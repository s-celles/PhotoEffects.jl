"""
Edge-only line art on a plain background.

`threshold` is evaluated against PhotoEffects' robust normalized Sobel edge
map, where the strongest common gradients approach one. `width` is the line
thickness in output pixels. Ink and background are explicit palette colours.
"""
struct LineArt <: AbstractEffect
    threshold::Float64
    width::Int
    line_color::RGB{N0f8}
    background::RGB{N0f8}

    function LineArt(; threshold::Real = 0.2, width::Integer = 1,
            line_color::Colorant = RGB(0.06, 0.07, 0.1),
            background::Colorant = RGB(0.97, 0.96, 0.92))
        isfinite(threshold) && 0 <= threshold <= 1 || throw(ArgumentError(
            "threshold must lie in [0, 1], got $threshold"))
        width >= 1 ||
            throw(ArgumentError("width must be >= 1, got $width"))
        return new(Float64(threshold), Int(width), RGB{N0f8}(line_color),
            RGB{N0f8}(background))
    end
end

_intrinsically_colored(::LineArt) = true

function _render(effect::LineArt, img::AbstractMatrix{RGB{N0f8}})
    edges = _edge_map(img)
    height, width = size(img)
    detected = edges .> effect.threshold
    radius = effect.width - 1
    out = fill(effect.background, height, width)
    @inbounds for x in 1:width, y in 1:height
        neighbourhood = detected[max(1, y - radius):min(height, y + radius),
            max(1, x - radius):min(width, x + radius)]
        any(neighbourhood) && (out[y, x] = effect.line_color)
    end
    return out
end
