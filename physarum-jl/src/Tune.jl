using BlackBoxOptim, JSON3
export run_tuning, save_params, load_params

"""
    phase1_objective(x; base_params, n_eval, seeds) -> Float64

Phase 1 BlackBoxOptim objective. Maximises pruning quality averaged
across n_eval replicates. Returns negative Q_prune (minimiser convention).

x = [decay_rate, deposit_amount, food_chemo, n_agents]
"""
function phase1_objective(x::Vector{Float64};
                           base_params::PhysarumParams,
                           n_eval::Int = 10,
                           seeds::Vector{Int} = collect(1:10))::Float64
    params = PhysarumParams(
        condition      = base_params.condition,
        v1             = base_params.v1,
        v2             = base_params.v2,
        decay_rate     = x[1],
        deposit_amount = x[2],
        food_chemo     = x[3],
        n_agents       = round(Int, x[4]),
        max_ticks      = base_params.max_ticks
    )

    scores = Vector{Float64}(undef, n_eval)
    Threads.@threads for i in 1:n_eval
        r = run_replicate(params, i, seeds[i])
        # Guard constraints (ADR-003): penalise failed runs
        if r.first_contact_tick == params.max_ticks ||
           r.x_cross_final == -9999.0
            scores[i] = 0.0
        else
            scores[i] = r.q_prune
        end
    end

    return -mean(scores)   # minimise negative = maximise Q_prune
end

function run_tuning(base_params::PhysarumParams;
                    time_budget_sec::Int = 300)::PhysarumParams
    error("run_tuning not yet implemented — see T020")
end

function save_params(params::PhysarumParams, path::String)
    error("save_params not yet implemented — see T020")
end

function load_params(path::String)::PhysarumParams
    error("load_params not yet implemented — see T020")
end
