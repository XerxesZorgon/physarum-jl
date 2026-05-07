using Statistics, Roots
export measure_x_cross, pruning_quality, snells_prediction

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

"""
    snells_prediction(params::PhysarumParams) -> Float64

Geometric Snell's Law prediction for x_cross. Finds the boundary
crossing x-coordinate (in NetLogo convention) that minimises total
travel time from source to food across the two-speed zone boundary.
Uses Roots.jl bisection on the Fermat stationarity condition.
"""
function snells_prediction(params::PhysarumParams)::Float64
    # Convert source and food from sim coords to NetLogo coords
    sx = netlogo_x(patch_idx(params.source_sim[1]))   # ≈ -75.0
    sy = netlogo_y(patch_idx(params.source_sim[2]))   # ≈ -75.0
    fx = netlogo_x(patch_idx(params.food_sim[1]))     # ≈  75.0
    fy = netlogo_y(patch_idx(params.food_sim[2]))     # ≈  75.0
    by = 0.0   # zone boundary in NetLogo y-coords

    # Zone speeds — effective_speeds handles :A, :B, :C
    v1, v2 = effective_speeds(params)

    # Fermat stationarity: d(T)/d(xc) = 0
    # T(xc) = hypot(xc-sx, by-sy)/v1 + hypot(fx-xc, fy-by)/v2
    # f(xc) = sin(θ1)/v1 - sin(θ2)/v2 = 0
    f(xc) = (xc - sx) / (v1 * hypot(xc - sx, by - sy)) -
            (fx - xc) / (v2 * hypot(fx - xc, fy - by))

    return find_zero(f, (-99.0, 99.0))
end
