using PhysarumSim, Statistics

# Load tuned parameters
params = load_params("results/tuned_params.json")

# :forward_only Condition B — Snell predicts x_cross ≈ −40.37
# Using n_agents = 2000 to ensure a clean wavefront for refraction measurement
p = PhysarumParams(params;
    condition = :B, init_mode = :forward_only,
    v1 = 1.0, v2 = 0.5, n_agents = 2000, max_ticks = 5000)
r = run_replicate(p, 1, 42)
println("forward_only Condition B (n_agents=2000, seed=42):")
println("  first_contact_tick:       ", r.first_contact_tick)
println("  x_cross_at_first_contact: ", r.x_cross_at_first_contact)
println("  x_cross_early (median):   ", r.x_cross_early)

@assert r.first_contact_tick > 0          "food not found"
@assert r.x_cross_at_first_contact < -20.0  "crossed right of center"
@assert r.x_cross_at_first_contact > -70.0  "crossed too far left"
println("Pilot :forward_only Condition B PASSED")
