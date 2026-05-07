using BlackBoxOptim, JSON3
export run_tuning, save_params, load_params

"""
    phase1_objective(x; base_params, n_eval, seeds) -> Float64

Phase 1 BlackBoxOptim objective. Maximises pruning quality averaged
across n_eval replicates. Returns negative Q_prune (minimiser convention).

x = [decay_rate, deposit_amount, food_chemo, n_agents]
"""
function phase1_objective(x::Vector{Float64};
                           base_params::PhysarumParams,
                           n_eval::Int = 10,
                           seeds::Vector{Int} = collect(1:10))::Float64
    params = PhysarumParams(
        condition      = base_params.condition,
        v1             = base_params.v1,
        v2             = base_params.v2,
        decay_rate     = x[1],
        deposit_amount = x[2],
        food_chemo     = x[3],
        n_agents       = round(Int, x[4]),
        max_ticks      = base_params.max_ticks,
        chemo_threshold_pct = base_params.chemo_threshold_pct
    )

    scores = Vector{Float64}(undef, n_eval)
    Threads.@threads for i in 1:n_eval
        r = run_replicate(params, i, seeds[i])
        # Guard constraints (ADR-003): penalise failed runs
        if r.first_contact_tick == params.max_ticks
            scores[i] = 0.0
        elseif r.x_cross_final == -9999.0
            scores[i] = 0.1   # partial credit: found food but no tube
        else
            scores[i] = r.q_prune
        end
    end

    return -mean(scores)   # minimise negative = maximise Q_prune
end

"""
    run_tuning(base_params; time_budget_sec) -> PhysarumParams

Run BlackBoxOptim Phase 1: maximise pruning quality over the four
tunable parameters. Returns the best PhysarumParams found.
"""
function run_tuning(base_params::PhysarumParams;
                    time_budget_sec::Int = 300)::PhysarumParams
    obj = x -> phase1_objective(x;
                    base_params = base_params,
                    n_eval      = 10,
                    seeds       = collect(1:10))

    result = bboptimize(obj;
        SearchRange  = [(0.05, 0.50),    # decay_rate
                        (2.0,  15.0),    # deposit_amount
                        (100.0, 2000.0), # food_chemo
                        (200.0, 800.0)], # n_agents (treated as Float64)
        NumDimensions = 4,
        Method        = :adaptive_de_rand_1_bin_radiuslimited,
        MaxTime       = Float64(time_budget_sec),
        TraceMode     = :compact)

    x = best_candidate(result)
    return PhysarumParams(
        condition      = base_params.condition,
        v1             = base_params.v1,
        v2             = base_params.v2,
        decay_rate     = x[1],
        deposit_amount = x[2],
        food_chemo     = x[3],
        n_agents       = round(Int, x[4]),
        max_ticks      = base_params.max_ticks,
        chemo_threshold_pct = base_params.chemo_threshold_pct
    )
end

"""
    save_params(params, path)

Serialise PhysarumParams to JSON at `path`.
"""
function save_params(params::PhysarumParams, path::String)
    open(path, "w") do io
        JSON3.write(io, params)
    end
end

"""
    load_params(path) -> PhysarumParams

Deserialise PhysarumParams from JSON at `path`.
"""
function load_params(path::String)::PhysarumParams
    d = JSON3.read(read(path, String))
    PhysarumParams(
        condition                = Symbol(d[:condition]),
        v1                       = Float64(d[:v1]),
        v2                       = Float64(d[:v2]),
        decay_rate               = Float64(d[:decay_rate]),
        deposit_amount           = Float64(d[:deposit_amount]),
        food_chemo               = Float64(d[:food_chemo]),
        n_agents                 = Int(d[:n_agents]),
        max_ticks                = Int(d[:max_ticks]),
        return_deposit_multiplier= Float64(get(d, :return_deposit_multiplier, 5.0)),
        food_chemo_fade          = Float64(get(d, :food_chemo_fade, 0.97)),
        beacon_chemo_fraction    = Float64(get(d, :beacon_chemo_fraction, 0.30))
    )
end
