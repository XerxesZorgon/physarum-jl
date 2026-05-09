using HypothesisTests, Statistics, DataFrames, CSV
export run_statistics, save_report

"""
    run_statistics(results, params) -> String

Compute and return a formatted statistical report covering:
  SC-1: null model (Condition C) ordering check
  SC-2: one-sample t-test of Condition A vs Snell's prediction
  SC-3: paired symmetry test (A + B vs 0)
"""
function run_statistics(results::Dict{Symbol,Vector{RunResult}},
                        params::PhysarumParams)::String

    buf = IOBuffer()

    # ── helpers ───────────────────────────────────────────────────────────────
    valid(rs) = [r.x_cross_final for r in rs if r.x_cross_final != -9999.0]
    cohens_d(xs, μ0) = isempty(xs) ? NaN : (mean(xs) - μ0) / std(xs)

    xs_A = valid(results[:A])
    xs_B = valid(results[:B])
    xs_C = valid(results[:C])

    pred_A = snells_prediction(PhysarumParams(params; condition=:A))
    pred_B = snells_prediction(PhysarumParams(params; condition=:B))

    n_A, n_B, n_C = length(xs_A), length(xs_B), length(xs_C)

    println(buf, "=" ^ 60)
    println(buf, "physarum-jl Statistical Report")
    println(buf, "=" ^ 60)
    println(buf, "Snell's Law predictions: A=$(round(pred_A,digits=2))  B=$(round(pred_B,digits=2))  C=0.0")
    println(buf, "Valid replicates: A=$n_A  B=$n_B  C=$n_C")
    println(buf)

    # ── SC-1: ordering test ────────────────────────────────────────────────────
    println(buf, "SC-1: Snell's Law ordering (A > C > B)")
    println(buf, "-" ^ 40)
    m_A = isempty(xs_A) ? NaN : mean(xs_A)
    m_B = isempty(xs_B) ? NaN : mean(xs_B)
    m_C = isempty(xs_C) ? NaN : mean(xs_C)
    ordered = m_A > m_C > m_B
    println(buf, "  mean_A = $(round(m_A, digits=2))")
    println(buf, "  mean_C = $(round(m_C, digits=2))")
    println(buf, "  mean_B = $(round(m_B, digits=2))")
    println(buf, "  Result: $(ordered ? "PASS ✓" : "FAIL ✗")")
    println(buf)

    # ── SC-2: one-sample t-test, Condition A vs prediction ────────────────────
    println(buf, "SC-2: Condition A vs Snell's Law prediction ($(round(pred_A,digits=2)) patches)")
    println(buf, "-" ^ 40)
    if n_A >= 3
        t_A   = OneSampleTTest(xs_A, pred_A)
        ci    = confint(t_A)
        p_val = pvalue(t_A)
        d     = cohens_d(xs_A, pred_A)
        println(buf, "  n = $n_A")
        println(buf, "  mean = $(round(m_A, digits=2))")
        println(buf, "  t = $(round(t_A.t, digits=3))  df = $(round(t_A.df, digits=1))")
        println(buf, "  p = $(round(p_val, digits=4))")
        println(buf, "  95% CI = [$(round(ci[1],digits=2)), $(round(ci[2],digits=2))]")
        println(buf, "  Cohen's d = $(round(d, digits=3))")
        verdict = if p_val < 0.05 && ci[1] > 0
            "confirmed (mean above 0, CI excludes 0)"
        elseif p_val < 0.05 && ci[2] < 0
            "rejected (mean below 0)"
        else
            "inconclusive (CI crosses 0 or p ≥ 0.05)"
        end
        println(buf, "  Verdict: $verdict")
    else
        println(buf, "  Insufficient valid replicates (n=$n_A < 3)")
    end
    println(buf)

    # ── SC-3: paired symmetry test ────────────────────────────────────────────
    println(buf, "SC-3: Paired symmetry (mean_A + mean_B ≈ 0)")
    println(buf, "-" ^ 40)
    n_paired = min(length(results[:A]), length(results[:B]))
    sums = [r_A.x_cross_final + r_B.x_cross_final
            for (r_A, r_B) in zip(results[:A][1:n_paired], results[:B][1:n_paired])
            if r_A.x_cross_final != -9999.0 && r_B.x_cross_final != -9999.0]
    if length(sums) >= 3
        t_sym = OneSampleTTest(sums, 0.0)
        p_sym = pvalue(t_sym)
        println(buf, "  n_pairs = $(length(sums))")
        println(buf, "  mean(A+B) = $(round(mean(sums), digits=2))  (target: 0.0)")
        println(buf, "  p = $(round(p_sym, digits=4))")
        sym_verdict = p_sym >= 0.05 ? "symmetric (fail to reject H0: mean=0)" :
                                      "asymmetric (reject H0)"
        println(buf, "  Verdict: $sym_verdict")
    else
        println(buf, "  Insufficient paired replicates")
    end
    println(buf)
    println(buf, "=" ^ 60)

    return String(take!(buf))
end

"""
    save_report(report, path)

Write the statistical report string to a text file.
"""
function save_report(report::String, path::String)
    open(path, "w") do io
        write(io, report)
    end
end
