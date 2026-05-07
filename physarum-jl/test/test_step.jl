using Test
using ..PhysarumSim

# ── S: Sensor sampling ────────────────────────────────────────────────────────

@testset "S: Sensor sampling" begin
    ps = PhysarumParams(n_agents=1, food_chemo=0.0, max_ticks=1)
    ms = build_model(ps, 1)
    props = abmproperties(ms)

    # S-01: Sensor pointing outside world clamps — no BoundsError
    @test PhysarumSim.sample_chemo(SVector(0.5, 0.5), -π/2, 9, props.chemo) isa Float64

    # S-02: Sensor returns correct value at known location
    # pos=(50.5,50.5), heading=0 (north), dist=9 →
    #   xi = patch_idx(50.5 + 0) = 51
    #   yj = patch_idx(50.5 + 9) = 60
    props.chemo[51, 60] = 42.0
    @test PhysarumSim.sample_chemo(SVector(50.5, 50.5), 0.0, 9, props.chemo) ≈ 42.0

    # S-03: All sensors return 0 in empty world
    empty_chemo = zeros(Float64, 201, 201)
    @test PhysarumSim.sample_chemo(SVector(100.5, 100.5), -π/4, 9, empty_chemo) == 0.0
    @test PhysarumSim.sample_chemo(SVector(100.5, 100.5),  0.0, 9, empty_chemo) == 0.0
    @test PhysarumSim.sample_chemo(SVector(100.5, 100.5), +π/4, 9, empty_chemo) == 0.0
end

# ── S: Turning logic ──────────────────────────────────────────────────────────
# All tests: agent at (50.5, 50.5), heading π/4 (NE), sa = π/4
# Sensor patches (food_chemo=0 so food doesn't interfere):
#   left  (heading  0):  [51, 60]
#   center(heading π/4): [57, 57]
#   right (heading π/2): [60, 51]

let p0 = PhysarumParams(n_agents=1, food_chemo=0.0, max_ticks=2),
    sa = deg2rad(p0.sensor_angle_deg)

    function fresh_agent(seed=99)
        m = build_model(p0, seed)
        a = first(allagents(m))
        move_agent!(a, SVector(50.5, 50.5), m)
        a.heading = π/4
        abmproperties(m).chemo .= 0.0
        return m, a
    end

    @testset "S: Turning logic" begin
        # S-04: Left sensor highest → turn left
        m4, a4 = fresh_agent()
        abmproperties(m4).chemo[51, 60] = 100.0
        h0 = a4.heading
        agent_step!(a4, m4)
        @test a4.heading ≈ h0 - sa  atol=1e-10

        # S-05: Right sensor highest → turn right
        m5, a5 = fresh_agent()
        abmproperties(m5).chemo[60, 51] = 100.0
        h0 = a5.heading
        agent_step!(a5, m5)
        @test a5.heading ≈ h0 + sa  atol=1e-10

        # S-06: Center sensor highest → no turn
        m6, a6 = fresh_agent()
        abmproperties(m6).chemo[57, 57] = 100.0
        h0 = a6.heading
        agent_step!(a6, m6)
        @test a6.heading ≈ h0  atol=1e-10

        # S-07: All sensors zero (tie) → no turn
        m7, a7 = fresh_agent()
        h0 = a7.heading
        agent_step!(a7, m7)
        @test a7.heading ≈ h0  atol=1e-10

        # S-08: Left == right > center → no turn
        m8, a8 = fresh_agent()
        abmproperties(m8).chemo[51, 60] = 100.0
        abmproperties(m8).chemo[60, 51] = 100.0
        h0 = a8.heading
        agent_step!(a8, m8)
        @test a8.heading ≈ h0  atol=1e-10
    end
end

@testset "S: Boundary respawn" begin
    pb = PhysarumParams(n_agents=1, food_chemo=0.0, max_ticks=200)

    # S-09: Agent near right wall heading east → stays within world
    m9 = build_model(pb, 1)
    a9 = first(allagents(m9))
    move_agent!(a9, SVector(199.5, 50.5), m9)
    a9.heading = π/2  # east — will overshoot right wall
    abmproperties(m9).chemo .= 0.0
    agent_step!(a9, m9)
    @test 0.0 <= a9.pos[1] <= 200.0
    @test 0.0 <= a9.pos[2] <= 200.0

    # S-10: After boundary hit, agent is near source (not near wall)
    src = pb.source_sim
    dist_to_src = hypot(a9.pos[1] - src[1], a9.pos[2] - src[2])
    @test dist_to_src <= pb.source_radius + 1.0

    # S-11: Agent near top wall heading north → respawned near source
    m11 = build_model(pb, 2)
    a11 = first(allagents(m11))
    move_agent!(a11, SVector(50.5, 199.9), m11)
    a11.heading = 0.0  # north — will overshoot top wall
    abmproperties(m11).chemo .= 0.0
    agent_step!(a11, m11)
    @test 0.0 <= a11.pos[1] <= 200.0
    @test 0.0 <= a11.pos[2] <= 200.0
    @test hypot(a11.pos[1] - src[1],
                a11.pos[2] - src[2]) <= pb.source_radius + 1.0

    # S-12: Agent near bottom wall heading south → respawned near source
    m12 = build_model(pb, 3)
    a12 = first(allagents(m12))
    move_agent!(a12, SVector(50.5, 0.5), m12)
    a12.heading = π  # south — will overshoot bottom wall
    abmproperties(m12).chemo .= 0.0
    agent_step!(a12, m12)
    @test 0.0 <= a12.pos[1] <= 200.0
    @test 0.0 <= a12.pos[2] <= 200.0

    # S-13: No agent escapes world bounds over 100 steps (unchanged)
    m13 = build_model(pb, 42)
    abmproperties(m13).chemo .= 0.0
    step!(m13, 100)
    for a in allagents(m13)
        @test 0.0 <= a.pos[1] <= 200.0
        @test 0.0 <= a.pos[2] <= 200.0
    end
end

# ── S: Mean filter diffusion ──────────────────────────────────────────────────

@testset "S: Mean filter diffusion" begin
    chemo = zeros(Float64, 201, 201)
    buf   = zeros(Float64, 201, 201)

    # S-14: Uniform field is unchanged
    chemo .= 5.0
    orig = copy(chemo)
    PhysarumSim.mean_filter!(chemo, buf)
    @test chemo ≈ orig

    # S-15: Single point source spreads to neighbours
    chemo .= 0.0
    chemo[101, 101] = 9.0
    PhysarumSim.mean_filter!(chemo, buf)
    @test chemo[100, 101] > 0.0

    # S-16: Interior mass approximately conserved (< 5% loss)
    chemo .= rand(201, 201)
    s0 = sum(chemo)
    PhysarumSim.mean_filter!(chemo, buf)
    @test abs(sum(chemo) - s0) / s0 < 0.05

    # S-17: Corner (1,1) averages only its 4 valid neighbours
    chemo .= 0.0
    chemo[1, 1] = 9.0
    PhysarumSim.mean_filter!(chemo, buf)
    @test chemo[1, 1] ≈ 9.0 / 4.0
end

# ── S: Decay and replenishment ────────────────────────────────────────────────

@testset "S: Decay and replenishment" begin
    # S-18: Interior patch decays by decay_rate after model_step!
    # Use uniform field so mean filter leaves values unchanged.
    p18 = PhysarumParams(n_agents=1, decay_rate=0.1, food_chemo=0.0, max_ticks=2)
    m18 = build_model(p18, 1)
    props18 = abmproperties(m18)
    props18.chemo .= 10.0
    PhysarumSim.model_step!(m18)
    @test props18.chemo[50, 50] ≈ 10.0 * (1.0 - p18.decay_rate)  atol=0.01

    # S-19: Food patch restored to food_chemo after model_step!
    p19 = PhysarumParams(n_agents=1, decay_rate=0.1, food_chemo=500.0, max_ticks=2)
    m19 = build_model(p19, 1)
    props19 = abmproperties(m19)
    food_idx = props19.food_idx[1]
    props19.chemo[food_idx] = 0.0   # zero it manually
    PhysarumSim.model_step!(m19)
    @test props19.chemo[food_idx] == p19.food_chemo

    # S-20: Source patch is NOT replenished — follows normal decay
    m20 = build_model(p19, 1)
    props20 = abmproperties(m20)
    src_idx = props20.source_idx[1]
    props20.chemo[src_idx] = 10.0
    before = props20.chemo[src_idx]
    PhysarumSim.model_step!(m20)
    @test props20.chemo[src_idx] < before

    # S-21: Values below 0.001 are zeroed
    p21 = PhysarumParams(n_agents=1, decay_rate=0.0, food_chemo=0.0, max_ticks=2)
    m21 = build_model(p21, 1)
    props21 = abmproperties(m21)
    props21.chemo .= 0.0
    props21.chemo[50, 50] = 0.0005
    PhysarumSim.model_step!(m21)
    @test props21.chemo[50, 50] == 0.0
end
