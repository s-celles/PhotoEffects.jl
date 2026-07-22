"""
Duotone effect: luminance mapped onto a colour ramp.

Every pixel is reduced to its luminance, then that single number indexes a
gradient built from `stops`. The photograph keeps its tonal structure but
loses its own hues entirely — the result reads as printed in two inks.

With two stops the whole image lies on a segment of RGB space, which is what
gives the flat, poster-like look. More stops bend the ramp: a third,
saturated midtone is the classic split-tone.

Because only luminance survives, the light and dark variants are a matter of
choosing pale or deep stops rather than of post-processing.
"""
struct Duotone <: AbstractEffect
    "Ramp stops, from shadows to highlights. At least two."
    stops::Vector{RGB{Float64}}

    function Duotone(stops::AbstractVector{<:Colorant})
        length(stops) >= 2 ||
            throw(ArgumentError("at least 2 stops are needed, got $(length(stops))"))
        return new([RGB{Float64}(RGB(s)) for s in stops])
    end
end

"""
Default ramp: deep indigo shadows to warm sand highlights.
"""
Duotone() = Duotone([RGB{Float64}(0.06, 0.09, 0.24),
                     RGB{Float64}(0.98, 0.91, 0.76)])

function _render(effect::Duotone, img::AbstractMatrix{RGB{N0f8}})
    stops = effect.stops
    n = length(stops)
    out = Matrix{RGB{N0f8}}(undef, size(img))

    @inbounds for i in eachindex(img)
        l = clamp(Float64(Gray(img[i])), 0.0, 1.0)
        # Position on the ramp, then the segment it falls in.
        pos = l * (n - 1)
        k = min(floor(Int, pos), n - 2)
        t = pos - k
        a, b = stops[k + 1], stops[k + 2]
        out[i] = RGB{N0f8}(clamp01(RGB(red(a) + t * (red(b) - red(a)),
                                       green(a) + t * (green(b) - green(a)),
                                       blue(a) + t * (blue(b) - blue(a)))))
    end
    return out
end
