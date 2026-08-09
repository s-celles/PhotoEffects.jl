"""
Engraving-style crossed hatching whose ink density follows shadow.

`spacing` and `width` are measured in output pixels. Up to three line
`layers` are rotated evenly around the supplied `angle`; progressively darker
tones activate more layers. The explicit ink and paper colours make the
effect intrinsically coloured for grayscale input.
"""
struct Hatching <: AbstractEffect
    spacing::Int
    width::Int
    layers::Int
    angle::Float64
    line_color::RGB{N0f8}
    background::RGB{N0f8}

    function Hatching(; spacing::Integer = 7, width::Integer = 1,
            layers::Integer = 3, angle::Real = π / 4,
            line_color::Colorant = RGB(0.08, 0.09, 0.12),
            background::Colorant = RGB(0.96, 0.94, 0.88))
        spacing >= 2 ||
            throw(ArgumentError("spacing must be >= 2, got $spacing"))
        1 <= width < spacing || throw(ArgumentError(
            "width must lie in 1:$(spacing - 1), got $width"))
        1 <= layers <= 3 ||
            throw(ArgumentError("layers must lie in 1:3, got $layers"))
        isfinite(angle) ||
            throw(ArgumentError("angle must be finite, got $angle"))
        return new(Int(spacing), Int(width), Int(layers), Float64(angle),
            RGB{N0f8}(line_color), RGB{N0f8}(background))
    end
end

_intrinsically_colored(::Hatching) = true

@inline function _on_hatch_line(x, y, angle, spacing, width)
    coordinate = x * cos(angle) + y * sin(angle)
    return mod(coordinate, spacing) < width
end

function _render(effect::Hatching, img::AbstractMatrix{RGB{N0f8}})
    height, width = size(img)
    out = fill(effect.background, height, width)
    @inbounds for x in 1:width, y in 1:height
        darkness = 1 - Float64(Gray(img[y, x]))
        for layer in 1:(effect.layers)
            darkness > (layer - 1) / effect.layers || continue
            angle = effect.angle + (layer - 1) * π / effect.layers
            if _on_hatch_line(
                x, y, angle, effect.spacing, effect.width)
                out[y, x] = effect.line_color
                break
            end
        end
    end
    return out
end
