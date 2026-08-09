"""
Impressionist brush strokes oriented by the local image gradient.

`strokes` controls the number of marks. Their centres use edge-aware seeding,
while `length` and `width` are measured in output pixels. In flat regions the
orientation comes from the deterministic `seed`; near structure it follows
the local luminance gradient. Every stroke samples its source colour.
"""
struct Brushes{S <: Seeding} <: AbstractEffect
    seeding::S
    length::Int
    width::Int
    seed::Int
    background::RGB{N0f8}

    function Brushes(seeding::Seeding; length::Integer = 9,
            width::Integer = 2, seed::Integer = 20260508,
            background::Colorant = RGB(0.96, 0.94, 0.88))
        length >= 1 ||
            throw(ArgumentError("length must be >= 1, got $length"))
        width >= 1 ||
            throw(ArgumentError("width must be >= 1, got $width"))
        width <= length || throw(ArgumentError(
            "width must be <= length, got width=$width and length=$length"))
        return new{typeof(seeding)}(seeding, Int(length), Int(width),
            Int(seed), RGB{N0f8}(background))
    end
end

function Brushes(; strokes::Integer = 1800, length::Integer = 9,
        width::Integer = 2, detail::Real = 1.4,
        background_weight::Real = 2.0, seed::Integer = 20260508,
        background::Colorant = RGB(0.96, 0.94, 0.88))
    seeding = Scatter(
        points = strokes, detail = detail, background = background_weight, seed = seed)
    return Brushes(seeding; length, width, seed, background)
end

_intrinsically_colored(::Brushes) = true

@inline function _segment_distance_squared(px, py, x1, y1, x2, y2)
    dx = x2 - x1
    dy = y2 - y1
    denominator = dx^2 + dy^2
    t = denominator == 0 ? 0.0 :
        clamp(((px - x1) * dx + (py - y1) * dy) / denominator, 0, 1)
    closest_x = x1 + t * dx
    closest_y = y1 + t * dy
    return (px - closest_x)^2 + (py - closest_y)^2
end

function _render(effect::Brushes, img::AbstractMatrix{RGB{N0f8}})
    points = sow(effect.seeding, img).points
    gray = Float64.(Gray.(img))
    gradient_y, gradient_x = imgradients(gray, KernelFactors.sobel)
    rng = StableRNG(effect.seed)
    height, image_width = size(img)
    out = fill(effect.background, height, image_width)
    half_length = effect.length / 2
    radius = effect.width / 2
    reach = ceil(Int, half_length + radius)

    @inbounds for point in points
        centre_x = clamp(round(Int, point[1]), 1, image_width)
        centre_y = clamp(round(Int, point[2]), 1, height)
        gx = gradient_x[centre_y, centre_x]
        gy = gradient_y[centre_y, centre_x]
        magnitude = hypot(gx, gy)
        if magnitude > eps(Float64)
            direction_x, direction_y = gx / magnitude, gy / magnitude
        else
            angle = 2π * rand(rng)
            direction_x, direction_y = cos(angle), sin(angle)
        end
        x1 = centre_x - half_length * direction_x
        y1 = centre_y - half_length * direction_y
        x2 = centre_x + half_length * direction_x
        y2 = centre_y + half_length * direction_y
        colour = img[centre_y, centre_x]

        for x in max(1, centre_x - reach):min(image_width, centre_x + reach)
            for y in max(1, centre_y - reach):min(height, centre_y + reach)
                _segment_distance_squared(x, y, x1, y1, x2, y2) <= radius^2 ||
                    continue
                out[y, x] = colour
            end
        end
    end
    return out
end
