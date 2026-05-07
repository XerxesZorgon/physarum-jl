using Agents, StaticArrays
export agent_step!, model_step!

# ── Internal helpers ──────────────────────────────────────────────────────────

function sample_chemo(pos::SVector{2,Float64}, heading::Float64,
                      dist::Int, chemo::Matrix{Float64})::Float64
    xi = clamp(patch_idx(pos[1] + dist * sin(heading)), 1, 201)
    yj = clamp(patch_idx(pos[2] + dist * cos(heading)), 1, 201)
    return chemo[xi, yj]
end

function mean_filter!(chemo::Matrix{Float64}, buf::Matrix{Float64})
    copy!(buf, chemo)
    rows, cols = size(chemo)
    @inbounds for j in 1:cols, i in 1:rows
        s, n = 0.0, 0
        for dj in -1:1, di in -1:1
            ni, nj = i + di, j + dj
            if 1 <= ni <= rows && 1 <= nj <= cols
                s += buf[ni, nj]
                n += 1
            end
        end
        chemo[i, j] = s / n
    end
end

# ── Agent step ────────────────────────────────────────────────────────────────

function agent_step!(agent::PhysarumAgent, model)
    props = abmproperties(model)
    p     = props.params
    sa    = deg2rad(p.sensor_angle_deg)

    # 1. Update speed from current patch zone
    agent.speed = props.medium_speed[patch_idx(agent.pos[1]),
                                     patch_idx(agent.pos[2])]

    # 2. Sense chemo at three forward sensor positions
    left   = sample_chemo(agent.pos, agent.heading - sa,
                           p.sensor_distance, props.chemo)
    center = sample_chemo(agent.pos, agent.heading,
                           p.sensor_distance, props.chemo)
    right  = sample_chemo(agent.pos, agent.heading + sa,
                           p.sensor_distance, props.chemo)

    # 3. Turn toward strongest signal; ties → no turn
    if left > right && left > center
        agent.heading -= sa
    elseif right > left && right > center
        agent.heading += sa
    end

    # 4. Compute intended new position
    nx = agent.pos[1] + agent.speed * sin(agent.heading)
    ny = agent.pos[2] + agent.speed * cos(agent.heading)

    # 5. Boundary: respawn at source (biologically motivated —
    #    Physarum retracts pseudopods that reach dead ends and
    #    redeploys from the main body)
    if nx < 0.0 || nx > 200.0 || ny < 0.0 || ny > 200.0
        rng   = abmrng(model)
        r_s   = props.params.source_radius * sqrt(rand(rng))
        θ_s   = 2π * rand(rng)
        nx    = clamp(props.params.source_sim[1] + r_s * cos(θ_s), 0.0, 200.0)
        ny    = clamp(props.params.source_sim[2] + r_s * sin(θ_s), 0.0, 200.0)
        agent.heading = 2π * rand(rng)
    end

    # 6. Move; update vel for bookkeeping
    agent.vel = SVector(agent.speed * sin(agent.heading),
                        agent.speed * cos(agent.heading))
    move_agent!(agent, SVector(nx, ny), model)

    # 7. Deposit chemoattractant; mark patch visited
    xi = patch_idx(agent.pos[1])
    yj = patch_idx(agent.pos[2])
    # Normalise by speed so deposit per unit path length is constant
    # across zones. Without this, slow zones are over-reinforced
    # (deposit/patch ∝ 1/v), biasing pruning away from the Snell path.
    props.chemo[xi, yj]   += p.deposit_amount * agent.speed
    props.visited[xi, yj]  = true

    # Log boundary x if this agent just entered a food patch
    if props.food_idx ∋ CartesianIndex(xi, yj) &&
       props.first_contact_tick > 0
        tick = props.last_tick
        window = max(1, round(Int, 0.05 * props.first_contact_tick))
        if tick <= props.first_contact_tick + window
            push!(props.early_arrivals, netlogo_x(xi))
        end
    end
end

# ── Model step ────────────────────────────────────────────────────────────────

function model_step!(model)
    props = abmproperties(model)
    p     = props.params

    # 1. Diffuse — 3×3 mean filter (ADR-002)
    mean_filter!(props.chemo, props.buf)

    # 2. Decay
    props.chemo .*= (1.0 - p.decay_rate)

    # 3. Zero sub-threshold values
    @. props.chemo = ifelse(props.chemo < 0.001, 0.0, props.chemo)

    # 4. Replenish food patches (Dirichlet source — applied after diffusion)
    for idx in props.food_idx
        props.chemo[idx] = p.food_chemo
    end

    # 5. First-contact detection
    tick = abmtime(model)
    if props.first_contact_tick == -1
        for idx in props.food_idx
            if props.visited[idx]
                props.first_contact_tick = tick
                break
            end
        end
    end

    # 6. Measure x_cross every tick after first contact
    if props.first_contact_tick > 0
        xc = measure_x_cross(props)
        push!(props.x_cross_history, (tick, xc))
    end

    # 7. Update last_tick
    props.last_tick = tick
end
