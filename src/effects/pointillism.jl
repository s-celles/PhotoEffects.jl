"""
Pointillist rendering made from deterministic, image-coloured dots.

`points` controls dot count, while `detail` and `background_weight` control
how strongly their density follows the source edges. Dot radii vary between
`min_radius` and `max_radius`, both measured in output pixels. `seed` fixes
the point positions, radii, and painting order.
"""
struct Pointillism{S <: Seeding} <: AbstractEffect
    seeding::S
    min_radius::Int
    max_radius::Int
    seed::Int
    background::RGB{N0f8}

    function Pointillism(seeding::Seeding; min_radius::Integer = 1,
            max_radius::Integer = 4, seed::Integer = 20260508,
            background::Colorant = RGB(0.96, 0.94, 0.88))
        min_radius >= 1 || throw(ArgumentError(
            "min_radius must be >= 1, got $min_radius"))
        max_radius >= min_radius || throw(ArgumentError(
            "max_radius must be >= min_radius, got $max_radius"))
        return new{typeof(seeding)}(seeding, Int(min_radius), Int(max_radius),
            Int(seed), RGB{N0f8}(background))
    end
end

function Pointillism(; points::Integer = 1200, min_radius::Integer = 1,
        max_radius::Integer = 4, detail::Real = 1.4,
        background_weight::Real = 2.0, seed::Integer = 20260508,
        background::Colorant = RGB(0.96, 0.94, 0.88))
    seeding = Scatter(; points, detail, background = background_weight, seed)
    return Pointillism(seeding; min_radius, max_radius, seed, background)
end

_intrinsically_colored(::Pointillism) = true

function _render(effect::Pointillism, img::AbstractMatrix{RGB{N0f8}})
    points = sow(effect.seeding, img).points
    rng = StableRNG(effect.seed)
    height, width = size(img)
    out = fill(effect.background, height, width)

    @inbounds for point in points
        centre_x = clamp(round(Int, point[1]), 1, width)
        centre_y = clamp(round(Int, point[2]), 1, height)
        radius = rand(rng, (effect.min_radius):(effect.max_radius))
        colour = img[centre_y, centre_x]
        for x in max(1, centre_x - radius):min(width, centre_x + radius)
            for y in max(1, centre_y - radius):min(height, centre_y + radius)
                (x - centre_x)^2 + (y - centre_y)^2 <= radius^2 || continue
                out[y, x] = colour
            end
        end
    end
    return out
end
