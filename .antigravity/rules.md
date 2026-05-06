# physarum-jl — Antigravity Rules

## Language & Runtime
- Julia 1.11. No syntax or features from newer versions.
- Runtime target: local workstation, multi-threaded (`julia -t auto`).

## Dependencies
- Do not add dependencies without updating Project.toml and noting it
  in the task report.
- Allowed libraries: Agents, BlackBoxOptim, CairoMakie, HypothesisTests,
  Roots, JSON3, CSV, DataFrames, StaticArrays, and stdlib
  (Statistics, Random, Test, LinearAlgebra).
- Dev-only: Revise, BenchmarkTools.

## Code Style
- Functions: 30 lines maximum. Split at natural boundaries if longer.
- No magic numbers: all numeric constants come from PhysarumParams or
  named module-level constants.
- No commented-out code. Dead code belongs in git history.
- No unused imports. Remove before committing.
- Docstrings required on all exported functions.

## Performance
- Use @inbounds on inner loops only when bounds are proven safe.
- No heap allocations in agent_step! hot path. Pre-allocate in build_model.
- Never speculative optimisation — profile first.

## Testing
- Run the full test suite after every file changed:
  `julia --project=. -e "using Pkg; Pkg.test()"`
- Do not commit if any test fails.
- Acceptance criteria are binary. Never report "seems to work".

## Scientific Integrity
- Do not modify PhysarumParams defaults without noting it in the task report.
- Coordinate conversions (patch_idx, netlogo_x, netlogo_y) must not change
  after T006 passes without updating test_model.jl.
- x_cross sentinel value is -9999.0. Do not change this value.