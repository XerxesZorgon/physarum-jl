# ADR-006: Three-mode Initialization Design
**Date:** 2026-05-10
**Status:** Accepted

## Context
v0.1.0 introduced an analytic beacon to guide returning agents, which ensures the final tube converges to the Snell's Law crossing point. However, this introduces a degree of "circularity" because the beacon placement relies on the analytic prediction it aims to verify. The Round 3 science council identified two non-circular alternatives to eliminate this dependency and further validate the emergent behavior. Checkpoint A demonstrated that the Phase 1 exploratory wavefront alone produces a crossing consistent with Snell's Law.

## Decision
Add an `init_mode::Symbol` field to `PhysarumParams` to support three distinct initialization and execution modes:

- **`:point_source` (default):** Backward compatible with v0.1.0. Agents spawn at a point source, use Phase 2 (returning agents), and the analytic beacon guides reinforcement.
- **`:forward_only`:** Agents spawn at a point source but Phase 2, beacon placement, and food fading are disabled. This mode tests the "pure" exploratory wavefront (Huygens principle). Primary measurement: `x_cross_at_first_contact`.
- **`:uniform`:** Agents are initialized uniformly across the domain (at `agent_density` fraction of patches). Zero initial trail. Two food sources are present: Food A (Zone 1) and Food B (Zone 2). Phase 2 and beacons are disabled. This matches the Nakagaki two-food design where the network emerges from bilateral gradients. Primary measurement: flux-weighted centroid of the boundary crossing.

## Consequences
- **Backward Compatibility:** Existing scripts and tests (using default `:point_source`) remain valid.
- **Measurement Changes:** Introduced mode-specific primary metrics (centroid vs max-chemo).
- **New Parameters:** Added `food_a_sim` (location of the second food source) and `agent_density` (for uniform initialization).
- **Model Logic:** `build_model`, `agent_step!`, and `model_step!` now dispatch behavior based on `init_mode`.
