"""
Topographic iso-luminance contours on a flat background.

`levels` partitions luminance into evenly spaced bands. Lines are drawn where
neighbouring pixels enter different bands; `width` is their thickness in
output pixels. The two explicit colours make this an intrinsically coloured
effect even for grayscale input.
"""
struct Contour <: AbstractEffect
    "Number of evenly spaced luminance bands."
    levels::Int
    "Contour thickness in output pixels."
    width::Int
    "Contour ink colour."
    line_color::RGB{N0f8}
    "Paper colour between contours."
    background::RGB{N0f8}

    function Contour(; levels::Integer = 8, width::Integer = 1,
            line_color::Colorant = RGB(0.08, 0.09, 0.12),
            background::Colorant = RGB(0.96, 0.94, 0.88))
        levels >= 2 ||
            throw(ArgumentError("levels must be >= 2, got $levels"))
        width >= 1 ||
            throw(ArgumentError("width must be >= 1, got $width"))
        return new(Int(levels), Int(width), RGB{N0f8}(line_color),
            RGB{N0f8}(background))
    end
end

_intrinsically_colored(::Contour) = true

function _render(effect::Contour, img::AbstractMatrix{RGB{N0f8}})
    height, width = size(img)
    bands = Matrix{Int}(undef, height, width)
    @inbounds for index in eachindex(img)
        luminance = Float64(Gray(img[index]))
        bands[index] = min(floor(Int, luminance * effect.levels),
            effect.levels - 1)
    end

    boundary = falses(height, width)
    @inbounds for x in 1:width, y in 1:height
        band = bands[y, x]
        boundary[y, x] = (x < width && bands[y, x + 1] != band) ||
                         (y < height && bands[y + 1, x] != band)
    end

    radius = effect.width - 1
    out = fill(effect.background, height, width)
    @inbounds for x in 1:width, y in 1:height
        neighbourhood = boundary[max(1, y - radius):min(height, y + radius),
            max(1, x - radius):min(width, x + radius)]
        any(neighbourhood) && (out[y, x] = effect.line_color)
    end
    return out
end
