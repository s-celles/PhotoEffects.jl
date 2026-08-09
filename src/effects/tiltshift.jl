"""
Progressive top-and-bottom blur for a miniature tilt-shift look.

`focus` locates the centre of the sharp horizontal band on the normalized
image height. `band` is its sharp fraction and `transition` is the fraction
over which it blends into the Gaussian blur. `radius` is measured in output
pixels.
"""
struct TiltShift <: AbstractEffect
    radius::Int
    focus::Float64
    band::Float64
    transition::Float64

    function TiltShift(; radius::Integer = 8, focus::Real = 0.5,
            band::Real = 0.25, transition::Real = 0.2)
        radius >= 1 ||
            throw(ArgumentError("radius must be >= 1, got $radius"))
        isfinite(focus) && 0 <= focus <= 1 ||
            throw(ArgumentError("focus must lie in [0, 1], got $focus"))
        isfinite(band) && 0 < band <= 1 ||
            throw(ArgumentError("band must lie in (0, 1], got $band"))
        isfinite(transition) && 0 < transition <= 1 || throw(ArgumentError(
            "transition must lie in (0, 1], got $transition"))
        return new(Int(radius), Float64(focus), Float64(band),
            Float64(transition))
    end
end

function _render(effect::TiltShift, img::AbstractMatrix{RGB{N0f8}})
    blurred = imfilter(img, Kernel.gaussian(effect.radius / 2))
    height, width = size(img)
    out = similar(img)
    @inbounds for x in 1:width, y in 1:height
        position = height == 1 ? effect.focus : (y - 1) / (height - 1)
        outside = abs(position - effect.focus) - effect.band / 2
        amount = _smoothstep(clamp(outside / effect.transition, 0, 1))
        sharp = RGB{Float64}(img[y, x])
        soft = RGB{Float64}(blurred[y, x])
        out[y, x] = RGB{N0f8}(
            (1 - amount) * sharp.r + amount * soft.r,
            (1 - amount) * sharp.g + amount * soft.g,
            (1 - amount) * sharp.b + amount * soft.b)
    end
    return out
end
