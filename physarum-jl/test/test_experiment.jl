using Test
using ..PhysarumSim
using CSV, DataFrames

@testset "I: Experiment — reproducibility and schema" begin
    p = PhysarumParams(max_ticks=200)

    # I-01: Same seed produces identical RunResult scalar fields
    r1 = run_replicate(p, 1, 7)
    r2 = run_replicate(p, 1, 7)
    @test r1.first_contact_tick      == r2.first_contact_tick
    @test r1.x_cross_final           == r2.x_cross_final
    @test r1.x_cross_at_first_contact == r2.x_cross_at_first_contact
    @test r1.q_prune                 == r2.q_prune
    @test r1.total_ticks             == r2.total_ticks

    # I-02: Different seeds produce different results
    r3 = run_replicate(p, 2, 999)
    # q_prune or x_cross_final should differ (probabilistic — fixed seeds)
    @test r1.q_prune != r3.q_prune || r1.x_cross_final != r3.x_cross_final

    # I-05: x_cross_history is non-empty when food is found
    # Run longer to increase chance of food contact
    p_long = PhysarumParams(max_ticks=2000)
    r_long = run_replicate(p_long, 1, 42)
    if r_long.first_contact_tick > 0
        @test length(r_long.x_cross_history) > 0
    else
        @test_skip "food not found in 2000 ticks — x_cross_history test skipped"
    end

    # I-07: CSV column names match ADR-004 schema exactly
    r_csv = run_replicate(p, 1, 1)
    tmp   = mktempdir()
    save_runs(Dict(:A => [r_csv]), tmp)
    df = CSV.read(joinpath(tmp, "runs_a.csv"), DataFrame)
    expected_cols = ["run_id", "condition", "seed", "v1", "v2",
                     "decay_rate", "deposit_amount", "food_chemo",
                     "n_agents", "first_contact_tick", "x_cross_final",
                     "x_cross_at_first_contact", "x_cross_early", "q_prune", "total_ticks"]
    @test names(df) == expected_cols

    # I-08: CSV round-trip preserves numeric fields to 6 decimal places
    @test df.q_prune[1]           ≈ r_csv.q_prune           atol=1e-6
    @test df.x_cross_final[1]     ≈ r_csv.x_cross_final     atol=1e-6
    @test df.first_contact_tick[1] == r_csv.first_contact_tick
end
