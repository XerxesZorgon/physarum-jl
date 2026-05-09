using PhysarumSim, CSV, DataFrames, Statistics, Agents

println("=" ^ 60)
println("physarum-jl — Analysis and Visualisation")
println("=" ^ 60)

# ── Load tuned parameters ─────────────────────────────────────────────────────
println("\nLoading parameters...")
params = load_params("results/tuned_params.json")

# ── Load Monte Carlo results from CSV ─────────────────────────────────────────
println("Loading Monte Carlo results from CSV...")
function load_results_from_csv(params, cond)
    cond_str = lowercase(string(cond))
    df = CSV.read("results/runs_$(cond_str).csv", DataFrame)
    map(eachrow(df)) do row
        p = PhysarumParams(params;
            condition      = Symbol(row.condition),
            v1             = row.v1,
            v2             = row.v2,
            decay_rate     = row.decay_rate,
            deposit_amount = row.deposit_amount,
            food_chemo     = row.food_chemo,
            n_agents       = row.n_agents)
        RunResult(
            row.run_id, Symbol(row.condition), row.seed, p,
            row.first_contact_tick,
            row.x_cross_final,
            row.x_cross_at_first_contact,
            row.x_cross_early,
            row.q_prune,
            row.total_ticks,
            Tuple{Int,Float64}[]   # x_cross_history not in CSV
        )
    end |> collect
end

results = Dict(cond => load_results_from_csv(params, cond)
               for cond in [:A, :B, :C])

println("  Loaded: A=$(length(results[:A])) B=$(length(results[:B])) C=$(length(results[:C])) replicates")

# ── Statistical report ────────────────────────────────────────────────────────
println("\nRunning statistical analysis...")
report = run_statistics(results, params)
println(report)
mkpath("results")
save_report(report, "results/stats_report.txt")
println("Saved: results/stats_report.txt")

# ── Figures ───────────────────────────────────────────────────────────────────
println("\nGenerating figures...")
mkpath("figures")

# Chemo field snapshots: one run each of Condition A and C
for (cond, seed) in [(:A, 100), (:C, 100)]
    p_snap = PhysarumParams(params; condition=cond)
    m_snap = build_model(p_snap, seed)
    step!(m_snap, p_snap.max_ticks)
    path = "figures/chemo_field_$(lowercase(string(cond))).png"
    plot_chemo_field(abmproperties(m_snap), path)
    println("  Saved: $path")
end

plot_xcross_distribution(results, params, "figures/xcross_distribution.png")
println("  Saved: figures/xcross_distribution.png")

plot_snells_comparison(results, params, "figures/snells_law_comparison.png")
println("  Saved: figures/snells_law_comparison.png")

println("\n" * "=" ^ 60)
println("Analysis complete.")
println("=" ^ 60)
