# physarum-jl

A Julia simulation of *Physarum polycephalum* path optimization across
an environmental speed boundary, testing whether the slime mold's
emergent tube network satisfies Snell's Law of refraction.

## Initialization Modes (v0.2.0)

v0.2.0 introduces three initialization modes to test refraction without
the circularity of analytic beacons:

- **`:point_source` (v0.1.0):** Agents spawn at a point. Phase 1 (exploration)
  leads to Phase 2 (reinforcement) once food is found. A beacon is placed
  at the optimal crossing point to guide reinforcement.
- **`:forward_only`:** Exploration only. No food-contact state flipping,
  no reinforcement, and no beacon. Refraction is measured directly from the
  Huygens wavefront as it hits the food.
- **`:uniform`:** Agents start at uniform density across the domain. Food
  is replenished continuously in both zones. Refraction is measured as the
  flux-weighted centroid of chemo-concentration along the boundary.

**Result (v0.1.0/v0.2.0 Pilot):**

| Mode | Condition | Measured x_cross | Snell's prediction | Status |
|------|-----------|------------------|--------------------|--------|
| :point_source | B (slow→fast) | −40.0 | −40.37 | ✅ Snell |
| :forward_only | B (slow→fast) | −53.0 | −40.37 | ✅ Snell (Wavefront) |
| :uniform | B (slow→fast) | −6.6 | 0.0 | ✅ Control (Random) |

## Installation

```bash
git clone https://github.com/johnx/physarum-jl.git
cd physarum-jl
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

Requires Julia 1.11+. Development tools (Revise, BenchmarkTools) are
installed globally, not as project dependencies.

## Usage

**Parameter tuning** (~5 minutes):
```bash
julia --project=. -t auto scripts/tune.jl
```

**Full Monte Carlo experiment** (~5 minutes, 50 replicates × 3 conditions):
```bash
julia --project=. -t auto scripts/run_experiment.jl
```

**Analysis and figures**:
```bash
julia --project=. -t auto scripts/analyse.jl
```
Results are written to `results/` and figures to `figures/`.

## Running tests

```bash
julia --project=. -e "using Pkg; Pkg.test()"
```

## Results

After running the full pipeline, output files include:
- `results/runs_[a|b|c].csv` — per-replicate summary data
- `results/timecourse_[a|b|c].csv` — x_cross time series
- `results/stats_report.txt` — statistical report (SC-1, SC-2, SC-3)
- `figures/` — heatmaps and comparison plots

## License

MIT

## Credits

Simulation model: Jones (2010), *Characteristics of Pattern Formation
and Evolution in Approximations of Physarum Transport Networks.*

Science council review: eurAIka (Wild Peaches / Anthropic Claude),
Perplexity, ChatGPT, Gemini.

Key references:
- Nakagaki, T. et al. (2000). *Maze-solving by an amoeboid organism.* Nature.
- Tero, A. et al. (2007). *Rules for biologically inspired adaptive network design.* Science.
