using Agents, CSV, DataFrames
export RunResult, run_replicate, run_condition, monte_carlo, save_runs

struct RunResult
    run_id::Int
    condition::Symbol
    seed::Int
    params::PhysarumParams
    first_contact_tick::Int
    x_cross_final::Float64
    x_cross_at_first_contact::Float64
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
    return RunResult(
        run_id,
        params.condition,
        seed,
        params,
        props.first_contact_tick,
        measure_x_cross(props),
        xc_at_contact,
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

function save_runs(results::Dict{Symbol,Vector{RunResult}},
                   results_dir::String)
    error("save_runs not yet implemented — see T015")
end
