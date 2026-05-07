using Test, PhysarumSim

@testset "PhysarumSim" begin
    include("test_model.jl")
    include("test_step.jl")
    include("test_measure.jl")
    include("test_experiment.jl")
    include("test_integration.jl")
end
