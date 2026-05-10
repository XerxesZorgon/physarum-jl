using Agents, StaticArrays, Random, Roots
export PhysarumParams, PhysarumAgent, PhysarumProperties,
       build_model, patch_idx, netlogo_x, netlogo_y, effective_speeds,
       snells_prediction

@kwdef struct PhysarumParams
    condition::Symbol          = :A
    v1::Float64                = 1.0
    v2::Float64                = 0.5
    n_agents::Int              = 400
    deposit_amount::Float64    = 5.0
    decay_rate::Float64        = 0.03
    food_chemo::Float64        = 500.0
    sensor_distance::Int       = 9
    sensor_angle_deg::Float64  = 45.0
    world_size::Int            = 201
    source_sim::NTuple{2,Float64} = (25.5, 25.5)
    food_sim::NTuple{2,Float64}   = (175.5, 175.5)
    source_radius::Float64     = 3.0
    food_radius::Float64       = 3.0
    max_ticks::Int             = 5000
    chemo_threshold_pct::Float64 = 0.70

    # Phase 2 — flow reinforcement parameters
    return_deposit_multiplier::Float64 = 5.0
    food_chemo_fade::Float64           = 0.97   # per-tick after first contact
    beacon_chemo_fraction::Float64     = 0.30   # beacon = fraction × food_chemo

    # v0.2.0 — three-mode parameters
    init_mode::Symbol              = :point_source   # :point_source | :forward_only | :uniform
    food_a_sim::NTuple{2,Float64}  = (25.5, 25.5)   # Food A (Zone 1) — uniform mode
    agent_density::Float64         = 0.10            # fraction of n² — uniform mode
end

# Copy constructor for easy parameter overriding
function PhysarumParams(p::PhysarumParams; kwargs...)
    d = Dict(k => getfield(p, k) for k in fieldnames(PhysarumParams))
    for (k, v) in kwargs
        d[k] = v
    end
    PhysarumParams(; d...)
end

function effective_speeds(p::PhysarumParams)
    p.condition == :B ? (p.v2, p.v1) :
    p.condition == :C ? (p.v1, p.v1) :
                        (p.v1, p.v2)
end

@agent struct PhysarumAgent(ContinuousAgent{2, Float64})
    heading::Float64
    speed::Float64
    returning::Bool
end

mutable struct PhysarumProperties
    chemo::Matrix{Float64}
    buf::Matrix{Float64}
    medium_speed::Matrix{Float64}
    visited::Matrix{Bool}
    food_idx::Vector{CartesianIndex{2}}
    food_a_idx::Vector{CartesianIndex{2}}   # Food A patches (empty for non-uniform)
    source_idx::Vector{CartesianIndex{2}}
    boundary_idx::Vector{CartesianIndex{2}}
    params::PhysarumParams
    first_contact_tick::Int
    x_cross_history::Vector{Tuple{Int,Float64}}
    early_arrivals::Vector{Float64}   # x_cross of agents arriving
                                      # within 5% of first_contact_tick
    last_tick::Int
    food_chemo_current::Float64                      # fades in Phase 2
    beacon_idx::Union{CartesianIndex{2}, Nothing}    # boundary beacon
    snells_xi::Int                                   # analytic prediction crossing column
end

function build_model(params::PhysarumParams, seed::Int)
    n = params.world_size
    space = ContinuousSpace((Float64(n), Float64(n)); periodic = false)

    # Zone speeds
    v1_eff, v2_eff = effective_speeds(params)
    medium_speed = Matrix{Float64}(undef, n, n)
    for j in 1:n, i in 1:n
        medium_speed[i, j] = j <= 100 ? v1_eff : v2_eff
    end

    # Precompute patch index sets
    food_idx = [CartesianIndex(i, j)
                for j in 1:n, i in 1:n
                if hypot(Float64(i-1) - params.food_sim[1] + 0.5,
                         Float64(j-1) - params.food_sim[2] + 0.5)
                   <= params.food_radius]

    source_idx = [CartesianIndex(i, j)
                  for j in 1:n, i in 1:n
                  if hypot(Float64(i-1) - params.source_sim[1] + 0.5,
                           Float64(j-1) - params.source_sim[2] + 0.5)
                     <= params.source_radius]

    boundary_idx = [CartesianIndex(i, j)
                    for j in (100, 101) for i in 1:n]

    food_a_idx = [CartesianIndex(i, j)
                  for j in 1:n, i in 1:n
                  if hypot(Float64(i-1) - params.food_a_sim[1] + 0.5,
                           Float64(j-1) - params.food_a_sim[2] + 0.5)
                     <= params.food_radius]

    # Chemo field — food initialised, source starts at zero
    chemo = zeros(Float64, n, n)
    for idx in food_idx
        chemo[idx] = params.food_chemo
    end
    if params.init_mode == :uniform
        for idx in food_a_idx
            chemo[idx] = params.food_chemo
        end
    end

    # Compute analytic prediction crossing column
    xc_pred   = snells_prediction(params)
    snells_xi = clamp(round(Int, xc_pred + 101.0), 1, 201)

    props = PhysarumProperties(
        chemo,
        zeros(Float64, n, n),       # buf
        medium_speed,
        falses(n, n),               # visited
        food_idx,
        food_a_idx,
        source_idx,
        boundary_idx,
        params,
        -1,                         # first_contact_tick
        Tuple{Int,Float64}[],       # x_cross_history
        Float64[],                  # early_arrivals
        0,                          # last_tick
        params.food_chemo,          # food_chemo_current
        nothing,                    # beacon_idx
        snells_xi                   # snells_xi
    )

    model = StandardABM(PhysarumAgent, space;
                        properties  = props,
                        agent_step! = agent_step!,
                        model_step! = model_step!,
                        rng         = Xoshiro(seed))

    # Spawn agents
    rng = abmrng(model)
    if params.init_mode == :uniform
        n_uniform = round(Int, params.agent_density * n * n)
        for _ in 1:n_uniform
            x = rand(rng) * (Float64(n) - 1e-6)
            y = rand(rng) * (Float64(n) - 1e-6)
            heading = 2π * rand(rng)
            spd = medium_speed[patch_idx(x), patch_idx(y)]
            add_agent!(SVector(x, y), model;
                       vel = SVector(0.0, 0.0), heading = heading,
                       speed = spd, returning = false)
        end
        println("Uniform mode: $n_uniform agents")
    else
        # :point_source and :forward_only — identical point-source spawn
        for _ in 1:params.n_agents
            r = params.source_radius * sqrt(rand(rng))
            θ = 2π * rand(rng)
            x = clamp(params.source_sim[1] + r * cos(θ), 0.0, Float64(n) - 1e-6)
            y = clamp(params.source_sim[2] + r * sin(θ), 0.0, Float64(n) - 1e-6)
            heading = 2π * rand(rng)
            spd = medium_speed[patch_idx(x), patch_idx(y)]
            add_agent!(SVector(x, y), model;
                       vel = SVector(0.0, 0.0), heading = heading,
                       speed = spd, returning = false)
        end
    end

    return model
end

"""
    patch_idx(x::Float64) -> Int

Convert a continuous simulation coordinate in [0.0, 201.0) to a
1-indexed matrix index in [1, 201]. Clamps out-of-range values.
"""
patch_idx(x::Float64)::Int = clamp(floor(Int, x) + 1, 1, 201)

"""
    netlogo_x(xi::Int) -> Float64

Convert a 1-indexed column index to NetLogo x-coordinate convention
(xi=1 → -100.0, xi=101 → 0.0, xi=201 → 100.0).
"""
netlogo_x(xi::Int)::Float64 = Float64(xi - 1 - 100)

"""
    netlogo_y(yj::Int) -> Float64

Convert a 1-indexed row index to NetLogo y-coordinate convention
(yj=1 → -100.0, yj=101 → 0.0, yj=201 → 100.0).
"""
netlogo_y(yj::Int)::Float64 = Float64(yj - 1 - 100)

"""
    snells_prediction(params::PhysarumParams) -> Float64

Geometric Snell's Law prediction for x_cross. Finds the boundary
crossing x-coordinate (in NetLogo convention) that minimises total
travel time from source to food across the two-speed zone boundary.
Uses Roots.jl bisection on the Fermat stationarity condition.
"""
function snells_prediction(params::PhysarumParams)::Float64
    # Convert source and food from sim coords to NetLogo coords
    sx = netlogo_x(patch_idx(params.source_sim[1]))   # ≈ -75.0
    sy = netlogo_y(patch_idx(params.source_sim[2]))   # ≈ -75.0
    fx = netlogo_x(patch_idx(params.food_sim[1]))     # ≈  75.0
    fy = netlogo_y(patch_idx(params.food_sim[2]))     # ≈  74.0
    by = 0.0   # zone boundary in NetLogo y-coords

    # Zone speeds — effective_speeds handles :A, :B, :C
    v1, v2 = effective_speeds(params)

    # Fermat stationarity: d(T)/d(xc) = 0
    # T(xc) = hypot(xc-sx, by-sy)/v1 + hypot(fx-xc, fy-by)/v2
    # f(xc) = sin(θ1)/v1 - sin(θ2)/v2 = 0
    f(xc) = (xc - sx) / (v1 * hypot(xc - sx, by - sy)) -
            (fx - xc) / (v2 * hypot(fx - xc, fy - by))

    return find_zero(f, (-99.0, 99.0))
end
