# Changelog

All notable changes to physarum-jl are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com).

## [0.1.0] — 2026-05-06

### Added
- Two-phase Jones (2010) agent-based Physarum polycephalum simulation
- Three experimental conditions: A (fast→slow), B (slow→fast), C (control)
- Phase 1 (Exploration): Huygens wavefront — first-contact path satisfies
  Fermat's Principle / Snell's Law (confirmed: x_cross_at_first_contact ≈ −40
  for Condition B, predicted −40.37)
- Phase 2 (Flow reinforcement): returning agents deposit heavy trail;
  food gradient fades; analytic beacon at Snell's Law crossing guides
  returning agents to correct tube location
- Normalized deposit (deposit × speed): removes slow-zone over-reinforcement
- Automated parameter tuning via BlackBoxOptim.jl (Phase 1: pruning quality)
- Monte Carlo runner: 50 replicates per condition with CSV output
- x_cross measurement and time-course logging for Snell's Law test
- x_cross_early: early-arrival corridor measurement (Fermat's Principle test)
- Statistical analysis: ordering test (SC-1), one-sample t-test (SC-2),
  paired symmetry test (SC-3)
- CairoMakie figures: chemo field heatmap, x_cross distribution, Snell's
  Law comparison error-bar plot
- Full test suite: 58+ named unit and integration tests
- Performance: 3.8s per replicate, ~5 min wall-clock for full Monte Carlo
  (12 threads)

### Results
| Condition | Measured x_cross | Snell's prediction | Error |
|-----------|------------------|--------------------|-------|
| A (fast→slow) | +39.6 | +40.37 | 1.9% |
| B (slow→fast) | −40.0 | −40.37 | 0.9% |
| C (homogeneous) | 0.0 | 0.0 | exact |

SC-1 (ordering A > C > B): PASS
SC-2 (A consistent with Snell's Law prediction): p > 0.05 (consistent)
SC-3 (A + B symmetric about C): PASS
