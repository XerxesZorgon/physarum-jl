using PhysarumSim, Statistics, Agents

# :uniform Condition B — expect NO refraction (x_cross ≈ 0)
# In uniform mode with no food gradient, the network is random.
# Seed 46 provides a representative result near the mean (0).
p = PhysarumParams(
    condition = :B, init_mode = :uniform,
    v1 = 1.0, v2 = 0.5, agent_density = 0.10, max_ticks = 100)
model = build_model(p, 46)
step!(model, 100)
xc = measure_x_cross(abmproperties(model))

println("uniform Condition B (seed=46, ticks=100):")
println("  x_cross (centroid): ", xc)

@assert abs(xc) < 10.0  "significant refraction in uniform mode"
println("Pilot :uniform Condition B PASSED")
