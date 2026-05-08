using CSV, DataFrames
for cond in ["a", "b", "c"]
    df = CSV.read("results/runs_$cond.csv", DataFrame)
    @assert nrow(df) == 50  "runs_$cond.csv: $(nrow(df)) rows, expected 50"
    println("runs_$cond.csv: $(nrow(df)) rows ✓")
end
for cond in ["a", "b", "c"]
    df = CSV.read("results/timecourse_$cond.csv", DataFrame)
    @assert nrow(df) > 0  "timecourse_$cond.csv is empty"
    println("timecourse_$cond.csv: $(nrow(df)) rows ✓")
end
println("PASS")
