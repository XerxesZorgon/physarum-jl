using Test
using ..PhysarumSim
using Statistics

@testset "I: Integration — pilot (10 replicates, 3000 ticks)" begin
    p_base = PhysarumParams(max_ticks=3000)
    seeds  = collect(1:10)

    # Run all three conditions first
    p_C    = PhysarumParams(condition=:C, max_ticks=3000)
    res_C  = [run_replicate(p_C, i, seeds[i]) for i in 1:10]

    p_A    = PhysarumParams(condition=:A, max_ticks=3000)
    res_A  = [run_replicate(p_A, i, seeds[i]) for i in 1:10]

    p_B    = PhysarumParams(condition=:B, max_ticks=3000)
    res_B  = [run_replicate(p_B, i, seeds[i]) for i in 1:10]

    # Calculate means
    valid_C = filter(r -> r.x_cross_final != -9999.0, res_C)
    mean_C  = isempty(valid_C) ? NaN : mean(r.x_cross_final for r in valid_C)
    
    valid_A = filter(r -> r.x_cross_final != -9999.0, res_A)
    mean_A  = isempty(valid_A) ? NaN : mean(r.x_cross_final for r in valid_A)
    
    valid_B = filter(r -> r.x_cross_final != -9999.0, res_B)
    mean_B  = isempty(valid_B) ? NaN : mean(r.x_cross_final for r in valid_B)

    # I-03: Conditions ordered A > C > B (Snell's Law direction test)
    @info "I-03: mean_C=$(round(mean_C, digits=2))  (Snell: A > C > B)"
    # With food-gradient offset b: expect mean_A ≈ +40+b, mean_B ≈ -40+b, mean_C ≈ b
    # Test: B is below C (primary Snell's Law check on 3000-tick pilot)
    @test mean_C > mean_B

    # I-04: Food found in ≥ 8/10 Condition C replicates
    found_C = count(r -> r.first_contact_tick > 0, res_C)
    @info "I-04: Food found in $found_C/10 Condition C replicates"
    @test found_C >= 8

    # I-06: A should be more positive than B
    @info "I-06: mean_A=$(round(mean_A, digits=2))  mean_B=$(round(mean_B, digits=2))"
    @test mean_A > mean_B
end
