"""
Radial vignette that darkens the image perimeter.

`strength` is the maximum corner attenuation. `start` is the normalized radial
distance at which the smooth falloff begins; zero starts at the centre and
values near one restrict it to the extreme corners. `strength=0` is identity.
"""
struct Vignette <: AbstractEffect
    strength::Float64
    start::Float64

    function Vignette(; strength::Real = 0.45, start::Real = 0.45)
        isfinite(strength) && 0 <= strength <= 1 || throw(ArgumentError(
            "strength must lie in [0, 1], got $strength"))
        isfinite(start) && 0 <= start < 1 ||
            throw(ArgumentError("start must lie in [0, 1), got $start"))
        return new(Float64(strength), Float64(start))
    end
end

@inline _smoothstep(value) = value^2 * (3 - 2value)

function _render(effect::Vignette, img::AbstractMatrix{RGB{N0f8}})
    effect.strength == 0 && return copy(img)
    height, width = size(img)
    centre_x = (width + 1) / 2
    centre_y = (height + 1) / 2
    scale_x = max((width - 1) / 2, 1)
    scale_y = max((height - 1) / 2, 1)
    out = similar(img)
    @inbounds for x in 1:width, y in 1:height
        distance = min(
            hypot((x - centre_x) / scale_x,
                (y - centre_y) / scale_y) / sqrt(2),
            1)
        progress = clamp((distance - effect.start) / (1 - effect.start), 0, 1)
        factor = 1 - effect.strength * _smoothstep(progress)
        colour = RGB{Float64}(img[y, x])
        out[y, x] = RGB{N0f8}(
            factor * colour.r, factor * colour.g, factor * colour.b)
    end
    return out
end

"""
Selective bloom that diffuses source highlights into neighbouring pixels.

Pixels brighter than `threshold` contribute to a Gaussian field whose
`radius` is measured in output pixels. `strength` controls the additive glow;
zero is an exact identity operation.
"""
struct Bloom <: AbstractEffect
    radius::Int
    strength::Float64
    threshold::Float64

    function Bloom(; radius::Integer = 8, strength::Real = 0.35,
            threshold::Real = 0.7)
        radius >= 1 ||
            throw(ArgumentError("radius must be >= 1, got $radius"))
        isfinite(strength) && 0 <= strength <= 1 || throw(ArgumentError(
            "strength must lie in [0, 1], got $strength"))
        isfinite(threshold) && 0 <= threshold < 1 || throw(ArgumentError(
            "threshold must lie in [0, 1), got $threshold"))
        return new(Int(radius), Float64(strength), Float64(threshold))
    end
end

function _render(effect::Bloom, img::AbstractMatrix{RGB{N0f8}})
    effect.strength == 0 && return copy(img)
    highlights = map(img) do pixel
        colour = RGB{Float64}(pixel)
        luminance = Float64(Gray(colour))
        weight = clamp(
            (luminance - effect.threshold) /
            (1 - effect.threshold), 0, 1)
        RGB(weight * colour.r, weight * colour.g, weight * colour.b)
    end
    glow = imfilter(highlights, Kernel.gaussian(effect.radius / 2))
    out = similar(img)
    @inbounds for index in eachindex(img)
        colour = RGB{Float64}(img[index])
        light = glow[index]
        out[index] = RGB{N0f8}(
            clamp(colour.r + effect.strength * light.r, 0, 1),
            clamp(colour.g + effect.strength * light.g, 0, 1),
            clamp(colour.b + effect.strength * light.b, 0, 1))
    end
    return out
end
