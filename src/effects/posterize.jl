"""
Posterisation: each channel snapped to `levels` values.

Continuous gradients collapse into hard bands, the way a screen-printed
poster reproduces a photograph with a limited number of inks. Unlike the
tessellation effects, the flat areas follow the tones rather than a geometry
laid over them.

`outline` optionally inks the contours, which turns the poster look into
cel-shading: the bands become fills and the edges become linework.

Snapping is pointwise, so photographic grain in a smooth area lands on either
side of a threshold at random and speckles the band with single-pixel
confetti. `smoothing` runs a median filter of that radius first, which flattens
the grain without softening the edges the way a blur would. Set it to zero to
snap the pixels exactly as they are, which makes the mapping idempotent:
re-applying then never lets the bands drift.

!!! note "Banding between channels is not noise"
    Each channel crosses its own thresholds at its own place, so a gradient
    picks up thin bands of colours that are in neither of its neighbours — the
    mauves and greens of a screen-printed sky. That is inherent to snapping
    channels independently, and `smoothing` does not remove it.
"""
struct Posterize <: AbstractEffect
    "Number of values kept per channel. Two gives eight colours in total."
    levels::Int
    "Edge strength above which a pixel is inked. Zero disables outlining."
    outline::Float64
    "Median filter radius applied before snapping. Zero snaps pixels as they are."
    smoothing::Int

    function Posterize(; levels::Integer = 8, outline::Real = 0.0,
                       smoothing::Integer = 1)
        levels >= 2 ||
            throw(ArgumentError("levels must be >= 2, got $levels"))
        outline >= 0 ||
            throw(ArgumentError("outline must be >= 0, got $outline"))
        smoothing >= 0 ||
            throw(ArgumentError("smoothing must be >= 0, got $smoothing"))
        return new(Int(levels), Float64(outline), Int(smoothing))
    end
end

function _render(effect::Posterize, img::AbstractMatrix{RGB{N0f8}})
    n = effect.levels
    out = Matrix{RGB{N0f8}}(undef, size(img))

    # Snap to the nearest of `n` values spread over [0, 1] inclusive, so that
    # pure black and pure white survive and the mapping is idempotent.
    quant(v) = round(clamp(v, 0, 1) * (n - 1)) / (n - 1)

    if effect.smoothing == 0
        @inbounds for i in eachindex(img)
            c = img[i]
            out[i] = RGB{N0f8}(quant(Float64(red(c))),
                               quant(Float64(green(c))),
                               quant(Float64(blue(c))))
        end
    else
        # Median rather than mean: it leaves a flat area untouched and refuses
        # to invent intermediate values across an edge, so the bands keep their
        # boundaries instead of gaining a soft quantised halo.
        w = 2 * effect.smoothing + 1
        cv = Float64.(channelview(img))
        r = mapwindow(median, view(cv, 1, :, :), (w, w))
        g = mapwindow(median, view(cv, 2, :, :), (w, w))
        b = mapwindow(median, view(cv, 3, :, :), (w, w))
        @inbounds for i in eachindex(out)
            out[i] = RGB{N0f8}(quant(r[i]), quant(g[i]), quant(b[i]))
        end
    end

    effect.outline == 0 && return out

    edges = _edge_map(img)
    @inbounds for i in eachindex(out)
        edges[i] >= effect.outline && (out[i] = RGB{N0f8}(0, 0, 0))
    end
    return out
end
