using Agents, CSV, DataFrames, Statistics
export RunResult, run_replicate, run_condition, monte_carlo, save_runs

struct RunResult
    run_id::Int
    condition::Symbol
    seed::Int
    params::PhysarumParams
    first_contact_tick::Int
    x_cross_final::Float64
    x_cross_at_first_contact::Float64
    x_cross_early::Float64   # median x_cross of early arrivals;
                             # -9999.0 if fewer than 3 arrivals logged
    q_prune::Float64
    total_ticks::Int
    x_cross_history::Vector{Tuple{Int,Float64}}
end

"""
    run_replicate(params, run_id, seed) -> RunResult

Build and run one model replicate to completion. Returns a RunResult
capturing all per-run measurements.
"""
function run_replicate(params::PhysarumParams,
                       run_id::Int, seed::Int)::RunResult
    model = build_model(params, seed)
    step!(model, params.max_ticks)
    props = abmproperties(model)
    history = props.x_cross_history
    xc_at_contact = isempty(history) ? -9999.0 : history[1][2]
    early = props.early_arrivals
    xc_early = length(early) >= 3 ? median(early) : -9999.0
    return RunResult(
        run_id,
        params.condition,
        seed,
        params,
        props.first_contact_tick,
        measure_x_cross(props),
        xc_at_contact,
        xc_early,
        pruning_quality(props),
        abmtime(model),
        copy(history)
    )
end

function run_condition(params::PhysarumParams,
                       seeds::Vector{Int})::Vector{RunResult}
    error("run_condition not yet implemented — see T022")
end

function monte_carlo(base_params::PhysarumParams,
                     n_reps::Int, base_seed::Int)
    error("monte_carlo not yet implemented — see T022")
end

"""
    save_runs(results, results_dir)

Write per-run summary CSVs and time-course CSVs for each condition
to `results_dir`. Creates the directory if it does not exist.

Output files per condition key (lowercased symbol):
  runs_[cond].csv       — one row per RunResult
  timecourse_[cond].csv — one row per (tick, x_cross) entry
"""
function save_runs(results::Dict{Symbol,Vector{RunResult}},
                   results_dir::String)
    mkpath(results_dir)

    for (cond, runs) in results
        cond_str = lowercase(string(cond))

        # ── Per-run summary ───────────────────────────────────────────
        run_rows = [(
            run_id                  = r.run_id,
            condition               = string(r.condition),
            seed                    = r.seed,
            v1                      = r.params.v1,
            v2                      = r.params.v2,
            decay_rate              = r.params.decay_rate,
            deposit_amount          = r.params.deposit_amount,
            food_chemo              = r.params.food_chemo,
            n_agents                = r.params.n_agents,
            first_contact_tick      = r.first_contact_tick,
            x_cross_final           = r.x_cross_final,
            x_cross_at_first_contact = r.x_cross_at_first_contact,
            x_cross_early           = r.x_cross_early,
            q_prune                 = r.q_prune,
            total_ticks             = r.total_ticks,
        ) for r in runs]

        CSV.write(joinpath(results_dir, "runs_$(cond_str).csv"),
                  DataFrame(run_rows))

        # ── Time-course ───────────────────────────────────────────────
        tc_rows = [(
            run_id    = r.run_id,
            condition = string(r.condition),
            tick      = t,
            x_cross   = xc,
        ) for r in runs for (t, xc) in r.x_cross_history]

        CSV.write(joinpath(results_dir, "timecourse_$(cond_str).csv"),
                  DataFrame(tc_rows))
    end
end
