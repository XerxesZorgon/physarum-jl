using PhysarumSim, Agents, Test, Statistics, StaticArrays

@testset "v0.2 Three-mode Initialization" begin

    @testset "V02-M (Model params)" begin
        # V02-M-01: all three modes construct PhysarumParams without error
        @test PhysarumParams(init_mode = :point_source).init_mode == :point_source
        @test PhysarumParams(init_mode = :forward_only).init_mode == :forward_only
        @test PhysarumParams(init_mode = :uniform).init_mode == :uniform

        # V02-M-02: default init_mode == :point_source
        @test PhysarumParams().init_mode == :point_source

        # V02-M-03: uniform agent_density default == 0.10
        @test PhysarumParams().agent_density == 0.10

        # V02-M-04: uniform agent count ≈ round(Int, 0.10×201×201) (±1)
        p_uni = PhysarumParams(init_mode = :uniform, agent_density = 0.10)
        m_uni = build_model(p_uni, 1)
        expected = round(Int, 0.10 * 201 * 201)
        @test abs(nagents(m_uni) - expected) <= 1

        # V02-M-05: uniform std(y-positions) > 50
        @test std([a.pos[2] for a in allagents(m_uni)]) > 50.0

        # V02-M-06: forward_only agent count == n_agents
        p_fo = PhysarumParams(init_mode = :forward_only, n_agents = 400)
        m_fo = build_model(p_fo, 1)
        @test nagents(m_fo) == 400

        # V02-M-07: uniform Food A chemo == food_chemo at init
        props_uni = abmproperties(m_uni)
        @test all(props_uni.chemo[idx] == p_uni.food_chemo for idx in props_uni.food_a_idx)

        # V02-M-08: forward_only Food A chemo == 0 at init
        props_fo = abmproperties(m_fo)
        @test all(props_fo.chemo[idx] == 0.0 for idx in props_fo.food_a_idx)
    end

    @testset "V02-S (Step behavior)" begin
        # V02-S-01: forward_only — no returning agents after 100 ticks
        p_fo = PhysarumParams(init_mode = :forward_only, agent_density = 0.02, max_ticks = 100)
        m_fo = build_model(p_fo, 7)
        step!(m_fo, 100)
        @test all(a.returning == false for a in allagents(m_fo))

        # V02-S-02: uniform — no returning agents after 100 ticks
        p_uni = PhysarumParams(init_mode = :uniform, agent_density = 0.02, max_ticks = 100)
        m_uni = build_model(p_uni, 8)
        step!(m_uni, 100)
        @test all(a.returning == false for a in allagents(m_uni))

        # V02-S-03: forward_only — food chemo ≥ 0.95×food_chemo after 200 ticks
        p_fo2 = PhysarumParams(init_mode = :forward_only, n_agents = 100, max_ticks = 200)
        m_fo2 = build_model(p_fo2, 9)
        step!(m_fo2, 200)
        props_fo2 = abmproperties(m_fo2)
        @test maximum(props_fo2.chemo[idx] for idx in props_fo2.food_idx) >= 0.95 * p_fo2.food_chemo

        # V02-S-04: forward_only — beacon_idx is nothing after 200 ticks
        @test isnothing(props_fo2.beacon_idx)

        # V02-S-05: uniform — Food A chemo ≥ 0.95×food_chemo after 200 ticks
        p_uni2 = PhysarumParams(init_mode = :uniform, agent_density = 0.02, max_ticks = 200)
        m_uni2 = build_model(p_uni2, 10)
        step!(m_uni2, 200)
        props_uni2 = abmproperties(m_uni2)
        @test maximum(props_uni2.chemo[idx] for idx in props_uni2.food_a_idx) >= 0.95 * p_uni2.food_chemo

        # V02-S-06: uniform — Food B chemo ≥ 0.95×food_chemo after 200 ticks
        @test maximum(props_uni2.chemo[idx] for idx in props_uni2.food_idx) >= 0.95 * p_uni2.food_chemo

        # V02-S-07: uniform — beacon_idx is nothing after 200 ticks
        @test isnothing(props_uni2.beacon_idx)
    end

    @testset "V02-X (Measure)" begin
        # V02-X-01: uniform centroid — dominant at +40, weak at 0 → result in [35, 42]
        p = PhysarumParams(init_mode = :uniform)
        m = build_model(p, 11)
        props = abmproperties(m)
        for j in [100, 101]
            props.visited[141, j] = true;  props.chemo[141, j] = 200.0
            props.visited[101, j] = true;  props.chemo[101, j] = 5.0
        end
        xc = measure_x_cross(props)
        @test 35.0 < xc < 42.0

        # V02-X-02: uniform centroid — symmetric ±40 → result near 0
        p2 = PhysarumParams(init_mode = :uniform)
        m2 = build_model(p2, 12)
        props2 = abmproperties(m2)
        for j in [100, 101]
            props2.visited[61, j]  = true;  props2.chemo[61, j]  = 100.0  # xi=61 → −40
            props2.visited[141, j] = true;  props2.chemo[141, j] = 100.0  # xi=141 → +40
        end
        @test abs(measure_x_cross(props2)) < 2.0

        # V02-X-03: forward_only — uses max-chemo path (not centroid)
        p3 = PhysarumParams(init_mode = :forward_only)
        m3 = build_model(p3, 13)
        props3 = abmproperties(m3)
        for i in 1:10
            props3.visited[i, 50] = true; props3.chemo[i, 50] = 10.0
        end
        props3.visited[141, 100] = true;  props3.chemo[141, 100] = 99.0
        @test measure_x_cross(props3) ≈ 40.0
    end

end
