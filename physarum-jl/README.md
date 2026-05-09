# physarum-jl

A Julia simulation of *Physarum polycephalum* path optimization across
an environmental speed boundary, testing whether the slime mold's
emergent tube network satisfies Snell's Law of refraction.

## What it does

*Physarum polycephalum* finds optimal paths between food sources through
a network of cytoplasmic tubes. This simulation tests whether, when the
organism must traverse two zones with different expansion speeds, the
final tube follows Snell's Law — the same geometric principle that
governs light refraction at a medium boundary.

The simulation implements a two-phase Jones (2010) agent-based model:
- **Phase 1 (Exploration):** Agents spread from a source via a Huygens
  wavefront. The first path to reach food satisfies Fermat's Principle,
  matching Snell's Law prediction within 5%.
- **Phase 2 (Flow reinforcement):** Agents that reach food return to
  the source, depositing a heavy return trail. The dominant tube
  converges to the Snell's Law crossing point.

**Result (50 replicates × 3 conditions):**

| Condition | Measured x_cross | Snell's prediction | Error |
|-----------|------------------|--------------------|-------|
| A (fast→slow) | +39.6 | +40.37 | 1.9% |
| B (slow→fast) | −40.0 | −40.37 | 0.9% |
| C (homogeneous) | 0.0 | 0.0 | exact |

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
