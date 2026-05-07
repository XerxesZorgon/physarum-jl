using Test
using ..PhysarumSim
using Statistics

@testset "I: Integration — pilot (10 replicates, 3000 ticks)" begin
    p_base = PhysarumParams(max_ticks=3000)
    seeds  = collect(1:10)

    # Run Condition C (homogeneous null model)
    p_C    = PhysarumParams(condition=:C, max_ticks=3000)
    res_C  = [run_replicate(p_C, i, seeds[i]) for i in 1:10]

    # Run Condition A
    p_A    = PhysarumParams(condition=:A, max_ticks=3000)
    res_A  = [run_replicate(p_A, i, seeds[i]) for i in 1:10]

    # Run Condition B
    p_B    = PhysarumParams(condition=:B, max_ticks=3000)
    res_B  = [run_replicate(p_B, i, seeds[i]) for i in 1:10]

    # I-03: Condition C mean x_cross within ±10 of 0
    valid_C = filter(r -> r.x_cross_final != -9999.0, res_C)
    mean_C  = isempty(valid_C) ? NaN : mean(r.x_cross_final for r in valid_C)
    @info "I-03: Condition C mean x_cross = $(round(mean_C, digits=2))"
    @test abs(mean_C) < 10.0

    # I-04: Food found in ≥ 8/10 Condition C replicates
    found_C = count(r -> r.first_contact_tick > 0, res_C)
    @info "I-04: Food found in $found_C/10 Condition C replicates"
    @test found_C >= 8

    # I-06: Condition B x_cross has opposite sign to Condition A
    valid_A = filter(r -> r.x_cross_final != -9999.0, res_A)
    valid_B = filter(r -> r.x_cross_final != -9999.0, res_B)
    mean_A  = isempty(valid_A) ? NaN : mean(r.x_cross_final for r in valid_A)
    mean_B  = isempty(valid_B) ? NaN : mean(r.x_cross_final for r in valid_B)
    @info "I-06: mean_A=$(round(mean_A, digits=2))  mean_B=$(round(mean_B, digits=2))"
    @test sign(mean_A) != sign(mean_B)
end
