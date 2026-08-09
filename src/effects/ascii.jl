const _ASCII_GLYPHS = (
    ("00000", "00000", "00000", "00000", "00000", "00000", "00000"), # space
    ("00000", "00000", "00000", "00000", "00000", "00000", "00100"), # .
    ("00000", "00000", "00100", "00000", "00000", "00100", "00000"), # :
    ("00000", "00000", "00000", "11111", "00000", "00000", "00000"), # -
    ("00000", "00000", "11111", "00000", "11111", "00000", "00000"), # =
    ("00100", "00100", "00100", "11111", "00100", "00100", "00100"), # +
    ("01010", "11111", "01010", "01010", "01010", "11111", "01010"), # #
    ("11111", "10001", "10001", "10101", "10001", "10001", "11111") # @
)

"""
Monospace ASCII art rendered with a built-in 5×7 bitmap density ramp.

Each glyph pixel is enlarged by integer `scale`, so a character cell measures
`5scale × 7scale` output pixels. The fixed ramp ` .:-=+#@` is ordered by
strictly increasing ink coverage. Partial cells at image edges are clipped.
"""
struct Ascii <: AbstractEffect
    scale::Int
    ink::RGB{N0f8}
    paper::RGB{N0f8}

    function Ascii(; scale::Integer = 2,
            ink::Colorant = RGB(0.06, 0.08, 0.1),
            paper::Colorant = RGB(0.96, 0.94, 0.88))
        scale >= 1 ||
            throw(ArgumentError("scale must be >= 1, got $scale"))
        return new(Int(scale), RGB{N0f8}(ink), RGB{N0f8}(paper))
    end
end

_intrinsically_colored(::Ascii) = true

function _render(effect::Ascii, img::AbstractMatrix{RGB{N0f8}})
    height, width = size(img)
    cell_width = 5effect.scale
    cell_height = 7effect.scale
    out = fill(effect.paper, height, width)

    for first_y in 1:cell_height:height, first_x in 1:cell_width:width
        last_y = min(first_y + cell_height - 1, height)
        last_x = min(first_x + cell_width - 1, width)
        luminance = mean(Float64.(Gray.(
            @view img[first_y:last_y, first_x:last_x])))
        glyph_index = clamp(
            floor(Int,
                (1 - luminance) * length(_ASCII_GLYPHS)) + 1,
            1, length(_ASCII_GLYPHS))
        glyph = _ASCII_GLYPHS[glyph_index]

        @inbounds for x in first_x:last_x, y in first_y:last_y
            glyph_x = fld(x - first_x, effect.scale) + 1
            glyph_y = fld(y - first_y, effect.scale) + 1
            glyph[glyph_y][glyph_x] == '1' && (out[y, x] = effect.ink)
        end
    end
    return out
end
