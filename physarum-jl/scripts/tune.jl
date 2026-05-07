using PhysarumSim, Statistics

println("=" ^ 60)
println("Phase 1 tuning — maximising pruning quality")
println("Time budget: 300 seconds | max_ticks per run: 2000")
println("=" ^ 60)

# Use max_ticks=2000 for tuning speed; food found ~tick 309
base = PhysarumParams(max_ticks=2000)
tuned = run_tuning(base; time_budget_sec=300)

println("\nTuned parameters:")
println("  decay_rate:     $(round(tuned.decay_rate,     digits=4))")
println("  deposit_amount: $(round(tuned.deposit_amount, digits=4))")
println("  food_chemo:     $(round(tuned.food_chemo,     digits=2))")
println("  n_agents:       $(tuned.n_agents)")

mkpath("results")
save_params(tuned, "results/tuned_params.json")
println("\nSaved to results/tuned_params.json")

# ── SC-1 validation ──────────────────────────────────────────────────────────
println("\n" * "=" ^ 60)
println("SC-1 validation: Condition C, 10 replicates, max_ticks=5000")
println("=" ^ 60)

# Validate at full max_ticks for the actual experiment
p_c = PhysarumParams(
    condition      = :C,
    v1             = tuned.v1,
    v2             = tuned.v2,
    decay_rate     = tuned.decay_rate,
    deposit_amount = tuned.deposit_amount,
    food_chemo     = tuned.food_chemo,
    n_agents       = tuned.n_agents,
    max_ticks      = 5000
)
res_c = [run_replicate(p_c, i, i) for i in 1:10]

found  = count(r -> r.first_contact_tick > 0, res_c)
valid  = filter(r -> r.x_cross_final != -9999.0, res_c)
mean_c = isempty(valid) ? NaN : mean(r.x_cross_final for r in valid)

println("  Food found:     $found/10")
println("  Mean x_cross:   $(round(mean_c, digits=2))  (target: |x| < 5.0)")

sc1 = abs(mean_c) <= 5.0 && found >= 8
println("\n  SC-1: $(sc1 ? "PASS ✓" : "FAIL ✗")")
!sc1 && println("  ⚠ Do not proceed to T022 — report results for review.")
