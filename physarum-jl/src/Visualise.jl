using CairoMakie, DataFrames, CSV, Statistics
export plot_chemo_field, plot_xcross_distribution, plot_snells_comparison

"""
    plot_chemo_field(props, output_path)

Heatmap of the chemoattractant field at run end.
"""
function plot_chemo_field(props::PhysarumProperties, output_path::String)
    n   = props.params.world_size
    fig = Figure(size = (700, 700))
    ax  = Axis(fig[1, 1];
               title  = "Condition $(props.params.condition) — tick $(props.last_tick)",
               xlabel = "x (NetLogo patches)",
               ylabel = "y (NetLogo patches)",
               xticks = (-100:50:100),
               yticks = (-100:50:100))

    # Build axis-labelled chemo matrix (columns = x, rows = y, flipped)
    chemo_display = props.chemo'   # transpose: rows=y, cols=x

    hm = heatmap!(ax, -100:100, -100:100, chemo_display;
                  colormap = :hot, colorrange = (0, props.params.food_chemo))
    Colorbar(fig[1, 2], hm; label = "Chemo concentration")

    # Zone boundary at y = 0
    hlines!(ax, [0.0]; color = :cyan, linewidth = 2, linestyle = :dash,
            label = "Zone boundary")

    # Source and food markers
    src_nl = (netlogo_x(patch_idx(props.params.source_sim[1])),
              netlogo_y(patch_idx(props.params.source_sim[2])))
    food_nl = (netlogo_x(patch_idx(props.params.food_sim[1])),
               netlogo_y(patch_idx(props.params.food_sim[2])))
    scatter!(ax, [src_nl[1]],  [src_nl[2]];
             color = :blue, markersize = 14, label = "Source")
    scatter!(ax, [food_nl[1]], [food_nl[2]];
             color = :green, markersize = 14, label = "Food")
    axislegend(ax; position = :lt)

    mkpath(dirname(output_path))
    save(output_path, fig)
    return nothing
end

"""
    plot_xcross_distribution(results, params, output_path)

Histogram of x_cross_final for each condition, with vertical lines
at Snell's Law predictions.
"""
function plot_xcross_distribution(results, params, output_path::String)
    pred_A = snells_prediction(PhysarumParams(params; condition=:A))
    pred_B = snells_prediction(PhysarumParams(params; condition=:B))

    fig = Figure(size = (800, 500))
    ax  = Axis(fig[1, 1];
               title  = "x_cross Distribution by Condition",
               xlabel = "x_cross (NetLogo patches)",
               ylabel = "Count")

    colours = Dict(:A => :firebrick, :B => :steelblue, :C => :forestgreen)
    for cond in [:A, :B, :C]
        xs = [r.x_cross_final for r in results[cond]
              if r.x_cross_final != -9999.0]
        isempty(xs) && continue
        hist!(ax, xs; bins = 20, color = (colours[cond], 0.5),
              label = "Condition $cond (n=$(length(xs)))")
    end

    vlines!(ax, [pred_A]; color = :firebrick, linewidth = 2,
            linestyle = :dash, label = "Pred A ($(round(pred_A,digits=1)))")
    vlines!(ax, [pred_B]; color = :steelblue, linewidth = 2,
            linestyle = :dash, label = "Pred B ($(round(pred_B,digits=1)))")
    vlines!(ax, [0.0]; color = :forestgreen, linewidth = 2,
            linestyle = :dash, label = "Pred C (0.0)")

    axislegend(ax; position = :rt)
    mkpath(dirname(output_path))
    save(output_path, fig)
    return nothing
end

"""
    plot_snells_comparison(results, params, output_path)

Error-bar plot: mean ± 95% CI of x_cross for each condition vs prediction.
"""
function plot_snells_comparison(results, params, output_path::String)
    pred_A = snells_prediction(PhysarumParams(params; condition=:A))
    pred_B = snells_prediction(PhysarumParams(params; condition=:B))
    preds  = Dict(:A => pred_A, :B => pred_B, :C => 0.0)
    conds  = [:A, :C, :B]   # display order

    means  = Float64[]
    lowers = Float64[]
    uppers = Float64[]
    labels = String[]
    pred_vals = Float64[]

    for cond in conds
        xs = [r.x_cross_final for r in results[cond]
              if r.x_cross_final != -9999.0]
        isempty(xs) && continue
        m  = mean(xs)
        se = std(xs) / sqrt(length(xs))
        ci = 1.96 * se
        push!(means, m); push!(lowers, ci); push!(uppers, ci)
        push!(labels, string(cond)); push!(pred_vals, preds[cond])
    end

    xs_pos = 1:length(means)
    fig = Figure(size = (600, 500))
    ax  = Axis(fig[1, 1];
               title   = "x_cross: Measured vs Snell's Law Prediction",
               ylabel  = "x_cross (NetLogo patches)",
               xticks  = (xs_pos, labels),
               xlabel  = "Condition")

    hlines!(ax, [0.0]; color = :grey70, linewidth = 1)
    errorbars!(ax, collect(xs_pos), means, lowers, uppers;
               color = :black, linewidth = 2, whiskerwidth = 10)
    scatter!(ax, collect(xs_pos), means;
             color = :black, markersize = 12, label = "Measured mean ± 95% CI")
    scatter!(ax, collect(xs_pos), pred_vals;
             color = :red, marker = :diamond, markersize = 12,
             label = "Snell's Law prediction")
    axislegend(ax; position = :rt)

    mkpath(dirname(output_path))
    save(output_path, fig)
    return nothing
end
