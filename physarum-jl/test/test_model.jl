using Test
using ..PhysarumSim

@testset "M: Coordinate utilities" begin

    # M-01 through M-03: patch_idx
    @test patch_idx(0.0)   == 1
    @test patch_idx(100.5) == 101
    @test patch_idx(200.9) == 201

    # M-04 through M-07: netlogo_x, netlogo_y
    @test netlogo_x(1)   == -100.0
    @test netlogo_x(101) ==    0.0
    @test netlogo_x(201) ==  100.0
    @test netlogo_y(1)   == -100.0

    # M-08: round-trip property
    for x in [-99.0, 0.0, 74.0]
        @test netlogo_x(patch_idx(x + 100.5)) ≈ floor(x) atol=1.0
    end

end
