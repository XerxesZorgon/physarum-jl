# Benchmark results (2026-05-06, hardware: 12 threads available):
# PERF-01: 3.8s (single thread)
# PERF-02: 6.9s (12 threads)
using PhysarumSim

println("=== PERF-01: Single replicate (default params, 1 thread) ===")
p = PhysarumParams()   # max_ticks=5000
t1 = @elapsed run_replicate(p, 1, 42)
println("Time: $(round(t1, digits=1))s  (target: < 240s)")
t1 > 240 && @warn "PERF-01 SLOW — see T018 On Failure in tasks.md"

println("\n=== PERF-02: 8 replicates threaded ===")
t2 = @elapsed begin
    results = Vector{RunResult}(undef, 8)
    Threads.@threads for i in 1:8
        results[i] = run_replicate(p, i, i)
    end
end
println("Threads: $(Threads.nthreads())  Time: $(round(t2, digits=1))s")

println("\n=== Summary ===")
println("PERF-01: $(round(t1, digits=1))s")
println("PERF-02: $(round(t2, digits=1))s  ($(Threads.nthreads()) threads)")
