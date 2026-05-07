using Test
using ..PhysarumSim

# ── X: x_cross measurement ────────────────────────────────────────────────────

@testset "X: measure_x_cross" begin
    p = PhysarumParams(food_chemo=0.0, n_agents=1, max_ticks=1)
    m = build_model(p, 1)
    props = abmproperties(m)

    # X-01: Empty world returns sentinel
    @test measure_x_cross(props) == -9999.0

    # X-02: No visited boundary patches returns sentinel
    # Mark only non-boundary patches as visited
    props.visited[50, 50] = true
    props.chemo[50, 50]   = 10.0
    @test measure_x_cross(props) == -9999.0

    # X-03: Single bright boundary patch returns correct NetLogo x
    # boundary rows are j=100 and j=101; column i=141 → netlogo_x=40.0
    props.chemo[141, 100]   = 100.0
    props.visited[141, 100] = true
    @test measure_x_cross(props) == 40.0

    # X-04: Multiple boundary patches — max-chemo wins
    props.chemo[120, 101]   = 50.0   # dimmer patch at x=19
    props.visited[120, 101] = true
    # chemo[141,100]=100 > chemo[120,101]=50 → xi=141 wins
    @test measure_x_cross(props) == 40.0

    # X-05: Boundary patch at column 101 returns x_cross == 0.0
    props2 = abmproperties(build_model(p, 2))
    props2.chemo[101, 100]   = 100.0
    props2.visited[101, 100] = true
    @test measure_x_cross(props2) == 0.0

    # X-06: High food/source chemo does not inflate threshold above
    #        boundary patches (food and source are excluded from τ calc)
    props3 = abmproperties(build_model(p, 3))
    # Manually set food patches very high
    for idx in props3.food_idx
        props3.chemo[idx]   = 1e6
        props3.visited[idx] = true
    end
    # Set a boundary patch with modest chemo
    props3.chemo[141, 100]   = 5.0
    props3.visited[141, 100] = true
    # Without food exclusion, τ would be huge and 5.0 wouldn't qualify
    # With food exclusion, τ ≈ quantile([5.0], 0.7) = 5.0 → qualifies
    @test measure_x_cross(props3) == 40.0
end

# ── Q: pruning_quality ────────────────────────────────────────────────────────

@testset "Q: pruning_quality" begin
    p = PhysarumParams(food_chemo=0.0, n_agents=1, max_ticks=1)

    # Q-01: No visited patches returns 0.0
    m1 = build_model(p, 1)
    @test pruning_quality(abmproperties(m1)) == 0.0

    # Q-02: All visited patches above threshold → low pruning quality
    m2 = build_model(p, 2)
    props2 = abmproperties(m2)
    # Fill interior with uniform high chemo
    for j in 10:50, i in 10:50
        props2.chemo[i, j]   = 100.0
        props2.visited[i, j] = true
    end
    @test pruning_quality(props2) < 0.5

    # Q-03: Most visited patches at zero chemo → high pruning quality.
    # Patches with chemo==0 are excluded from the interior_chemo list,
    # so only the single bright patch contributes — pruning quality ≈ 1.
    m3 = build_model(p, 3)
    props3 = abmproperties(m3)
    for j in 10:50, i in 10:50
        props3.visited[i, j] = true   # chemo stays 0.0
    end
    props3.chemo[50, 50]   = 100.0   # single surviving tube patch
    props3.visited[50, 50] = true
    @test pruning_quality(props3) > 0.9
end

# ── P: Snell's Law prediction ─────────────────────────────────────────────────

@testset "P: snells_prediction" begin
    pA = PhysarumParams(condition=:A)
    pB = PhysarumParams(condition=:B)
    pC = PhysarumParams(condition=:C)

    # P-01: Homogeneous (v1==v1) → prediction ≈ 0
    @test abs(snells_prediction(pC)) < 1.0

    # P-02: Condition A → prediction ≈ +40
    @test 38.0 < snells_prediction(pA) < 42.0

    # P-03: Condition B → prediction ≈ -40
    @test -42.0 < snells_prediction(pB) < -38.0

    # P-04: Verify prediction satisfies Snell's Law equation at x_cross
    xc = snells_prediction(pA)
    sx, sy = -75.0, -75.0
    fx, fy =  75.0,  75.0
    by     =   0.0
    sinθ1 = (xc - sx) / hypot(xc - sx, by - sy)
    sinθ2 = (fx - xc) / hypot(fx - xc, fy - by)
    v1, v2 = PhysarumSim.effective_speeds(pA)
    @test abs(sinθ1 / sinθ2 - v1 / v2) < 0.01
end
