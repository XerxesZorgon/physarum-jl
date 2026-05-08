using PhysarumSim, Statistics

println("=" ^ 60)
println("Phase 1 tuning — maximising pruning quality")
println("Time budget: 300 seconds | max_ticks per run: 3000")
println("=" ^ 60)

# Use max_ticks=3000 for tuning speed; food found ~tick 309
base = PhysarumParams(max_ticks=3000, chemo_threshold_pct=0.60)
tuned = run_tuning(base; time_budget_sec=300)

println("\nTuned parameters:")
println("  decay_rate:     $(round(tuned.decay_rate,     digits=4))")
println("  deposit_amount: $(round(tuned.deposit_amount, digits=4))")
println("  food_chemo:     $(round(tuned.food_chemo,     digits=2))")
println("  n_agents:       $(tuned.n_agents)")

mkpath("results")
save_params(tuned, "results/tuned_params.json")
println("\nSaved to results/tuned_params.json")

# ── Snell's Law direction validation (replaces old SC-1) ──────────────
println("\n" * "=" ^ 60)
println("Direction validation: 5 reps each condition, max_ticks=5000")
println("=" ^ 60)

means = Dict{Symbol, Float64}()
for cond in [:A, :B, :C]
    pc = PhysarumParams(tuned; condition=cond, max_ticks=5000)
    rs = [run_replicate(pc, i, i) for i in 1:5]
    valid = filter(r -> r.x_cross_final != -9999.0, rs)
    found = count(r -> r.first_contact_tick > 0, rs)
    m = isempty(valid) ? NaN : mean(r.x_cross_final for r in valid)
    means[cond] = m
    println("  $cond: mean=$(round(m, digits=1))  found=$found/5  valid=$(length(valid))/5")
end

# Snell's Law ordering: A > C > B
ordered = means[:A] > means[:C] > means[:B]
# Differentials in right direction
diff_A = means[:A] - means[:C]
diff_B = means[:B] - means[:C]
println("\n  A-C = $(round(diff_A, digits=1))  (predicted +40.37)")
println("  B-C = $(round(diff_B, digits=1))  (predicted -40.37)")
println("\n  Ordering A>C>B: $(ordered ? "PASS ✓" : "FAIL ✗")")
ordered || println("  ⚠ Do not proceed to T022 — report for review.")
