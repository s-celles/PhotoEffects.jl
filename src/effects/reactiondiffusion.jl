"""
Photo-tinted Gray–Scott reaction–diffusion patterns.

The two chemical fields evolve with periodic boundaries, making the generated
texture tileable. `iterations`, `feed`, `kill`, diffusion coefficients, and
`dt` control the kinetics. Seeded `spots` of pixel radius `spot_radius`
initiate the pattern, which modulates the source colours rather than replacing
their hue.
"""
struct ReactionDiffusion <: AbstractEffect
    iterations::Int
    feed::Float64
    kill::Float64
    diffusion_u::Float64
    diffusion_v::Float64
    dt::Float64
    spots::Int
    spot_radius::Int
    seed::Int

    function ReactionDiffusion(; iterations::Integer = 80,
            feed::Real = 0.055, kill::Real = 0.062,
            diffusion_u::Real = 0.16, diffusion_v::Real = 0.08,
            dt::Real = 1.0, spots::Integer = 12,
            spot_radius::Integer = 3, seed::Integer = 20260508)
        iterations >= 1 || throw(ArgumentError(
            "iterations must be >= 1, got $iterations"))
        isfinite(feed) && 0 <= feed <= 1 ||
            throw(ArgumentError("feed must lie in [0, 1], got $feed"))
        isfinite(kill) && 0 <= kill <= 1 ||
            throw(ArgumentError("kill must lie in [0, 1], got $kill"))
        isfinite(diffusion_u) && diffusion_u > 0 ||
            throw(ArgumentError("diffusion_u must be finite and positive"))
        isfinite(diffusion_v) && diffusion_v > 0 ||
            throw(ArgumentError("diffusion_v must be finite and positive"))
        isfinite(dt) && 0 < dt <= 1 ||
            throw(ArgumentError("dt must lie in (0, 1], got $dt"))
        spots >= 1 ||
            throw(ArgumentError("spots must be >= 1, got $spots"))
        spot_radius >= 1 || throw(ArgumentError(
            "spot_radius must be >= 1, got $spot_radius"))
        return new(Int(iterations), Float64(feed), Float64(kill),
            Float64(diffusion_u), Float64(diffusion_v), Float64(dt),
            Int(spots), Int(spot_radius), Int(seed))
    end
end

function _gray_scott_step!(next_u, next_v, u, v, effect)
    height, width = size(u)
    @inbounds for x in 1:width, y in 1:height
        left, right = mod1(x - 1, width), mod1(x + 1, width)
        above, below = mod1(y - 1, height), mod1(y + 1, height)
        laplacian_u = u[y, left] + u[y, right] + u[above, x] + u[below, x] -
                      4u[y, x]
        laplacian_v = v[y, left] + v[y, right] + v[above, x] + v[below, x] -
                      4v[y, x]
        reaction = u[y, x] * v[y, x]^2
        next_u[y, x] = clamp(
            u[y, x] +
            effect.dt *
            (effect.diffusion_u * laplacian_u - reaction +
             effect.feed * (1 - u[y, x])),
            0,
            1)
        next_v[y, x] = clamp(
            v[y, x] +
            effect.dt *
            (effect.diffusion_v * laplacian_v + reaction -
             (effect.feed + effect.kill) * v[y, x]),
            0,
            1)
    end
    return next_u, next_v
end

function _reaction_fields(effect, img)
    height, width = size(img)
    u = ones(Float64, height, width)
    v = 0.05 .* (1 .- Float64.(Gray.(img)))
    rng = StableRNG(effect.seed)
    for _ in 1:(effect.spots)
        centre_x = rand(rng, 1:width)
        centre_y = rand(rng, 1:height)
        @inbounds for dx in (-effect.spot_radius):(effect.spot_radius)
            for dy in (-effect.spot_radius):(effect.spot_radius)
                dx^2 + dy^2 <= effect.spot_radius^2 || continue
                x = mod1(centre_x + dx, width)
                y = mod1(centre_y + dy, height)
                u[y, x] = 0.5
                v[y, x] = 0.25
            end
        end
    end
    next_u, next_v = similar(u), similar(v)
    for _ in 1:(effect.iterations)
        _gray_scott_step!(next_u, next_v, u, v, effect)
        u, next_u = next_u, u
        v, next_v = next_v, v
    end
    return u, v
end

function _render(effect::ReactionDiffusion,
        img::AbstractMatrix{RGB{N0f8}})
    _, field = _reaction_fields(effect, img)
    minimum_value, maximum_value = extrema(field)
    scale = maximum_value > minimum_value ?
            1 / (maximum_value - minimum_value) : 0.0
    out = similar(img)
    @inbounds for index in eachindex(img)
        pattern = scale == 0 ? field[index] :
                  (field[index] - minimum_value) * scale
        factor = 0.35 + 0.65 * (1 - pattern)
        colour = RGB{Float64}(img[index])
        out[index] = RGB{N0f8}(
            factor * colour.r, factor * colour.g, factor * colour.b)
    end
    return out
end
