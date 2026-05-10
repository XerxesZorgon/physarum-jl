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
    #    Returning agents (point_source only) bypass sensor logic and navigate directly:
    #      Zone 2 (above boundary) → head to beacon
    #      Zone 1 (below boundary) → head to source
    if props.params.init_mode == :point_source
        if agent.returning
            p = props.params
            if !isnothing(props.beacon_idx)
                bx = Float64(props.beacon_idx[1]) - 0.5   # beacon sim x
                by = Float64(props.beacon_idx[2]) - 0.5   # beacon sim y
                if agent.pos[2] > by
                    # Still in Zone 2: steer toward beacon crossing
                    agent.heading = atan(bx - agent.pos[1],
                                         by - agent.pos[2])
                else
                    # Crossed boundary into Zone 1: steer toward source
                    agent.heading = atan(p.source_sim[1] - agent.pos[1],
                                         p.source_sim[2] - agent.pos[2])
                end
            else
                # Beacon not yet set: head directly toward source
                agent.heading = atan(p.source_sim[1] - agent.pos[1],
                                     p.source_sim[2] - agent.pos[2])
            end
        else
            if left > right && left > center
                agent.heading -= sa
            elseif right > left && right > center
                agent.heading += sa
            end
        end
    else
        # :forward_only and :uniform — exploration only, no Phase 2
        if left > right && left > center
            agent.heading -= sa
        elseif right > left && right > center
            agent.heading += sa
        end
    end

    # 4. Compute intended new position
    nx = agent.pos[1] + agent.speed * sin(agent.heading)
    ny = agent.pos[2] + agent.speed * cos(agent.heading)

    # 5. Reflective boundaries
    if nx < 0.0 || nx > 200.0
        agent.heading = -agent.heading
        nx = agent.pos[1] + agent.speed * sin(agent.heading)
    end
    if ny < 0.0 || ny > 200.0
        agent.heading = π - agent.heading
        ny = agent.pos[2] + agent.speed * cos(agent.heading)
    end
    nx = clamp(nx, 0.0, 200.0)
    ny = clamp(ny, 0.0, 200.0)

    # 6. Move; update vel for bookkeeping
    agent.vel = SVector(agent.speed * sin(agent.heading),
                        agent.speed * cos(agent.heading))
    move_agent!(agent, SVector(nx, ny), model)

    # 7. Deposit chemoattractant; mark patch visited
    xi = patch_idx(agent.pos[1])
    yj = patch_idx(agent.pos[2])
    # Returning agents deposit at amplified rate (flow reinforcement)
    deposit_multiplier        = agent.returning ? p.return_deposit_multiplier : 1.0
    props.chemo[xi, yj]    += p.deposit_amount * agent.speed * deposit_multiplier
    props.visited[xi, yj]   = true

    # Phase 2: food contact and return behavior (point_source only)
    if props.params.init_mode == :point_source
        if !agent.returning && CartesianIndex(xi, yj) ∈ props.food_idx
            agent.returning = true
            agent.heading  += π
        end

        if agent.returning
            if hypot(agent.pos[1] - p.source_sim[1],
                     agent.pos[2] - p.source_sim[2]) <= p.source_radius
                agent.returning = false
                agent.heading   = 2π * rand(abmrng(model))
            end
        end
    end

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
    tick  = abmtime(model)

    # 1. Diffuse — 3×3 mean filter (ADR-002)
    mean_filter!(props.chemo, props.buf)

    # 2. Decay
    props.chemo .*= (1.0 - p.decay_rate)

    # 3. Zero sub-threshold values
    @. props.chemo = ifelse(props.chemo < 0.001, 0.0, props.chemo)

    # 4. Replenish food and manage beacon
    if props.params.init_mode == :point_source
        # v0.1.0 — food fade + beacon unchanged
        if props.first_contact_tick > 0
            props.food_chemo_current = max(
                p.food_chemo * 0.05,
                props.food_chemo_current * p.food_chemo_fade)
        end
        for idx in props.food_idx
            props.chemo[idx] = props.food_chemo_current
        end
        if props.first_contact_tick > 0 && isnothing(props.beacon_idx)
            # Place beacon at analytically predicted column, boundary row j=100
            props.beacon_idx = CartesianIndex(props.snells_xi, 100)
        end
        if !isnothing(props.beacon_idx)
            props.chemo[props.beacon_idx] += p.food_chemo * p.beacon_chemo_fraction
        end

    elseif props.params.init_mode == :forward_only
        # Single food, continuous replenishment, no fade, no beacon
        for idx in props.food_idx
            props.chemo[idx] = p.food_chemo
        end

    else  # :uniform
        # Two foods, both replenished continuously, no beacon
        for idx in props.food_idx        # Food B (Zone 2)
            props.chemo[idx] = p.food_chemo
        end
        for idx in props.food_a_idx      # Food A (Zone 1)
            props.chemo[idx] = p.food_chemo
        end
    end

    # 5. First-contact detection
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
