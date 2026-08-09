"""
Inner border or print mat that preserves the image dimensions.

`width` is measured inward from every edge in output pixels. Values larger
than half an image dimension simply fill the complete image. A zero-width
border is an exact identity operation.
"""
struct Border <: AbstractEffect
    width::Int
    color::RGB{N0f8}

    function Border(; width::Integer = 12,
            color::Colorant = RGB(0.96, 0.94, 0.88))
        width >= 0 ||
            throw(ArgumentError("width must be >= 0, got $width"))
        return new(Int(width), RGB{N0f8}(color))
    end
end

_intrinsically_colored(::Border) = true

function _render(effect::Border, img::AbstractMatrix{RGB{N0f8}})
    effect.width == 0 && return copy(img)
    height, width = size(img)
    out = copy(img)
    @inbounds for x in 1:width, y in 1:height
        if x <= effect.width || x > width - effect.width ||
           y <= effect.width || y > height - effect.width
            out[y, x] = effect.color
        end
    end
    return out
end
