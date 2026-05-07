using Agents, StaticArrays, Random
export PhysarumParams, PhysarumAgent, PhysarumProperties,
       build_model, patch_idx, netlogo_x, netlogo_y

"""
    patch_idx(x::Float64) -> Int

Convert a continuous simulation coordinate in [0.0, 201.0) to a
1-indexed matrix index in [1, 201]. Clamps out-of-range values.

# Examples
    patch_idx(0.0)   == 1
    patch_idx(100.5) == 101
    patch_idx(200.9) == 201
"""
patch_idx(x::Float64)::Int = clamp(floor(Int, x) + 1, 1, 201)

"""
    netlogo_x(xi::Int) -> Float64

Convert a 1-indexed column index to NetLogo x-coordinate convention
(xi=1 → -100.0, xi=101 → 0.0, xi=201 → 100.0).
"""
netlogo_x(xi::Int)::Float64 = Float64(xi - 1 - 100)

"""
    netlogo_y(yj::Int) -> Float64

Convert a 1-indexed row index to NetLogo y-coordinate convention
(yj=1 → -100.0, yj=101 → 0.0, yj=201 → 100.0).
"""
netlogo_y(yj::Int)::Float64 = Float64(yj - 1 - 100)
