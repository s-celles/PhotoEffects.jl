"""
Source-coloured particle trails advected through the image gradient.

`particles` and `steps` control trail count and length. `step_size` and
`width` are measured in output pixels. Where the luminance gradient vanishes,
a deterministic procedural direction field keeps particles moving. The
`seed` controls both initial positions and the fallback field.
"""
struct FlowField <: AbstractEffect
    particles::Int
    steps::Int
    step_size::Float64
    width::Int
    detail::Float64
    background_weight::Float64
    seed::Int
    background::RGB{N0f8}

    function FlowField(; particles::Integer = 900, steps::Integer = 14,
            step_size::Real = 1.5, width::Integer = 1,
            detail::Real = 1.0, background_weight::Real = 2.0,
            seed::Integer = 20260508,
            background::Colorant = RGB(0.96, 0.94, 0.88))
        particles >= 1 || throw(ArgumentError(
            "particles must be >= 1, got $particles"))
        steps >= 1 ||
            throw(ArgumentError("steps must be >= 1, got $steps"))
        isfinite(step_size) && step_size > 0 ||
            throw(ArgumentError("step_size must be finite and positive"))
        width >= 1 ||
            throw(ArgumentError("width must be >= 1, got $width"))
        isfinite(detail) && detail >= 0 ||
            throw(ArgumentError("detail must be finite and non-negative"))
        isfinite(background_weight) && background_weight >= 0 || throw(
            ArgumentError("background_weight must be finite and non-negative"))
        return new(Int(particles), Int(steps), Float64(step_size), Int(width),
            Float64(detail), Float64(background_weight), Int(seed),
            RGB{N0f8}(background))
    end
end

_intrinsically_colored(::FlowField) = true

@inline function _procedural_flow_direction(effect, x, y)
    phase = sin(0.073x + 0.11effect.seed) +
            cos(0.061y - 0.07effect.seed)
    angle = π * phase
    return cos(angle), sin(angle)
end

function _flow_path(effect::FlowField, gradient_x, gradient_y, start)
    height, width = size(gradient_x)
    path = SVector{2, Float64}[SVector(start...)]
    for _ in 1:(effect.steps)
        current = path[end]
        x = clamp(round(Int, current[1]), 1, width)
        y = clamp(round(Int, current[2]), 1, height)
        gx = gradient_x[y, x]
        gy = gradient_y[y, x]
        magnitude = hypot(gx, gy)
        direction_x, direction_y = magnitude > eps(Float64) ?
                                   (gx / magnitude, gy / magnitude) :
                                   _procedural_flow_direction(
            effect, current...)
        next_point = SVector(
            clamp(current[1] + effect.step_size * direction_x, 1, width),
            clamp(current[2] + effect.step_size * direction_y, 1, height))
        push!(path, next_point)
    end
    return path
end

function _render(effect::FlowField, img::AbstractMatrix{RGB{N0f8}})
    seeding = Scatter(points = effect.particles, detail = effect.detail,
        background = effect.background_weight, seed = effect.seed)
    starts = sow(seeding, img).points
    gray = Float64.(Gray.(img))
    gradient_y, gradient_x = imgradients(gray, KernelFactors.sobel)
    height, image_width = size(img)
    out = fill(effect.background, height, image_width)
    radius = effect.width / 2
    reach = ceil(Int, radius)

    for start in starts
        path = _flow_path(effect, gradient_x, gradient_y, start)
        for index in 1:(length(path) - 1)
            first, second = path[index], path[index + 1]
            first_x, first_y = first
            second_x, second_y = second
            sample_x = clamp(round(Int, first_x), 1, image_width)
            sample_y = clamp(round(Int, first_y), 1, height)
            colour = img[sample_y, sample_x]
            minimum_x = max(1, floor(Int, min(first_x, second_x)) - reach)
            maximum_x = min(image_width,
                ceil(Int, max(first_x, second_x)) + reach)
            minimum_y = max(1, floor(Int, min(first_y, second_y)) - reach)
            maximum_y = min(height,
                ceil(Int, max(first_y, second_y)) + reach)
            @inbounds for x in minimum_x:maximum_x, y in minimum_y:maximum_y
                _segment_distance_squared(x, y, first_x, first_y,
                    second_x, second_y) <= radius^2 || continue
                out[y, x] = colour
            end
        end
    end
    return out
end
