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

@testset "M: Model construction" begin
    p  = PhysarumParams()
    m  = build_model(p, 42)
    props = abmproperties(m)

    # M-09: agent count
    @test nagents(m) == p.n_agents

    # M-10: all agents within source radius (+ small float tolerance)
    for a in allagents(m)
        dist = hypot(a.pos[1] - p.source_sim[1],
                     a.pos[2] - p.source_sim[2])
        @test dist <= p.source_radius + 0.01
    end

    # M-11: headings are in [0, 2π) and not all identical
    headings = [a.heading for a in allagents(m)]
    @test all(0.0 .<= headings .< 2π)
    @test length(unique(headings)) > 1

    # M-12: Zone 1 (rows j=1:100) has medium_speed == v1
    @test all(props.medium_speed[i, j] == p.v1
              for j in 1:100, i in 1:p.world_size)

    # M-13: Zone 2 (rows j=101:201) has medium_speed == v2
    @test all(props.medium_speed[i, j] == p.v2
              for j in 101:p.world_size, i in 1:p.world_size)

    # M-14: Condition :B swaps zone speeds
    pb = PhysarumParams(condition = :B)
    mb = build_model(pb, 1)
    propsb = abmproperties(mb)
    @test all(propsb.medium_speed[i, j] == pb.v2
              for j in 1:100, i in 1:pb.world_size)
    @test all(propsb.medium_speed[i, j] == pb.v1
              for j in 101:pb.world_size, i in 1:pb.world_size)

    # M-15: Condition :C — both zones equal v1
    pc = PhysarumParams(condition = :C)
    mc = build_model(pc, 1)
    propsc = abmproperties(mc)
    @test all(propsc.medium_speed .== pc.v1)

    # M-16: food patches initialised to food_chemo
    @test all(props.chemo[idx] == p.food_chemo for idx in props.food_idx)

    # M-17: source patches start at chemo == 0
    @test all(props.chemo[idx] == 0.0 for idx in props.source_idx)

    # M-18: first_contact_tick initialised to -1
    @test props.first_contact_tick == -1
end
