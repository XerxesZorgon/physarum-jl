using Statistics
export measure_x_cross, pruning_quality

"""
    measure_x_cross(props::PhysarumProperties) -> Float64

Return the NetLogo x-coordinate of the dominant tube crossing at the
zone boundary (rows j=100, j=101). Returns -9999.0 if no boundary patch
clears the threshold or no visited patches exist.
"""
function measure_x_cross(props::PhysarumProperties)::Float64
    # 1. Collect chemo values from interior visited non-zero patches
    interior = Float64[]
    for idx in findall(props.visited)
        c = props.chemo[idx]
        if c > 0.0 && idx ∉ props.food_idx && idx ∉ props.source_idx
            push!(interior, c)
        end
    end
    isempty(interior) && return -9999.0

    # 2. Threshold: chemo_threshold_pct percentile of interior values
    τ = quantile(interior, props.params.chemo_threshold_pct)

    # 3. Find boundary patch (j=100 or j=101) with maximum chemo ≥ τ
    best_idx   = nothing
    best_chemo = -Inf
    for idx in props.boundary_idx
        c = props.chemo[idx]
        if props.visited[idx] && c >= τ && c > best_chemo
            best_chemo = c
            best_idx   = idx
        end
    end
    isnothing(best_idx) && return -9999.0

    # 4. idx[1] is the column index (x direction)
    return netlogo_x(best_idx[1])
end

"""
    pruning_quality(props::PhysarumProperties) -> Float64

Return the fraction of visited interior patches that have faded to
background. 0.0 = no pruning; 1.0 = fully pruned to single tube.
"""
function pruning_quality(props::PhysarumProperties)::Float64
    interior = Float64[]
    for idx in findall(props.visited)
        c = props.chemo[idx]
        if c > 0.0 && idx ∉ props.food_idx && idx ∉ props.source_idx
            push!(interior, c)
        end
    end
    isempty(interior) && return 0.0

    τ        = quantile(interior, props.params.chemo_threshold_pct)
    n_active = count(c -> c >= τ, interior)
    n_total  = count(props.visited) - length(props.food_idx) -
                                      length(props.source_idx)
    n_total <= 0 && return 0.0

    return max(0.0, 1.0 - n_active / n_total)
end


