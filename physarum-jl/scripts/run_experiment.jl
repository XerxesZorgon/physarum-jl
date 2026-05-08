using PhysarumSim, Statistics

println("=" ^ 60)
println("physarum-jl — Full Monte Carlo experiment")
println("=" ^ 60)

println("\nLoading tuned parameters...")
params = load_params("results/tuned_params.json")
println("  decay_rate:     $(round(params.decay_rate, digits=4))")
println("  deposit_amount: $(round(params.deposit_amount, digits=4))")
println("  food_chemo:     $(round(params.food_chemo, digits=2))")
println("  n_agents:       $(params.n_agents)")
println("  max_ticks:      $(params.max_ticks)")

n_reps    = 50
base_seed = 100

println("\nRunning Monte Carlo: $n_reps replicates × 3 conditions...")
println("(Using $(Threads.nthreads()) threads)")
t_start = time()
results = monte_carlo(params, n_reps, base_seed)
t_elapsed = round(time() - t_start, digits=1)
println("Completed in $(t_elapsed)s")

println("\nSummary:")
for cond in [:A, :B, :C]
    rs    = results[cond]
    found = count(r -> r.first_contact_tick > 0, rs)
    valid = filter(r -> r.x_cross_final != -9999.0, rs)
    m     = isempty(valid) ? NaN : mean(r.x_cross_final for r in valid)
    println("  Condition $cond: $(found)/$n_reps found food, " *
            "mean x_cross = $(round(m, digits=1)) " *
            "($(length(valid))/$n_reps valid)")
end

mkpath("results")
save_runs(results, "results")
println("\nSaved to results/")
println("  runs_a.csv, runs_b.csv, runs_c.csv")
println("  timecourse_a.csv, timecourse_b.csv, timecourse_c.csv")
