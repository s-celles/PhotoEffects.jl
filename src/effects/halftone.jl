"""
Mark shape stamped in each halftone cell.
"""
module HalftoneShape
@enum T begin
    DOT
    SQUARE
end
end

"""
Halftone screen: tone rendered as varying dot area on a tilted grid.

The image is covered by a regular lattice of cells. Each cell is inked over
a fraction of its area proportional to the local darkness — a small dot in
the highlights, a fat one in the shadows, merging into solid ink in the
blacks. Seen from far enough the eye integrates the coverage back into a
continuous tone; up close it is offset printing, or Lichtenstein.

The output holds **two colours only**, `ink` and `paper`: a halftone
simulates grey through area, never through intermediate tones.

The lattice is rotated by `angle` because an unrotated screen aligns with the
pixel grid and beats against it, producing moiré. The traditional monochrome
screen angle is 45°, far from both horizontal and vertical.

Each cell takes its tone from the **mean** luminance over the cell, not from
the single pixel at its centre: a screen integrates the area it covers, and
sampling one pixel instead lets grain and fine texture set the dot size, which
turns rock and foliage into static rather than into tone.

`gamma` bends the tone-to-area curve. A photograph whose tones sit around the
middle screens to near-50% coverage everywhere, where a dot pattern carries
almost no image; raising `gamma` above one opens the highlights back up, which
is the same correction a press makes for dot gain.

!!! warning "`cell` is in pixels"
    Like the brush radius of [`Oil`](@ref), it must scale with the output
    width, otherwise the screen is coarse at one resolution and invisible at
    another.
"""
struct Halftone <: AbstractEffect
    "Lattice pitch, in pixels."
    cell::Int
    "Lattice rotation, in radians."
    angle::Float64
    "Mark shape stamped in each cell."
    shape::HalftoneShape.T
    "Exponent bending the tone-to-area curve. One keeps area proportional to darkness."
    gamma::Float64
    "Colour laid down by the screen."
    ink::RGB{N0f8}
    "Colour left bare."
    paper::RGB{N0f8}

    function Halftone(; cell::Integer = 8,
                      angle::Real = π / 4,
                      shape::HalftoneShape.T = HalftoneShape.DOT,
                      gamma::Real = 1.8,
                      ink::Colorant = RGB{N0f8}(0, 0, 0),
                      paper::Colorant = RGB{N0f8}(1, 1, 1))
        cell >= 2 || throw(ArgumentError("cell must be >= 2, got $cell"))
        gamma > 0 || throw(ArgumentError("gamma must be > 0, got $gamma"))
        return new(Int(cell), Float64(angle), shape, Float64(gamma),
                   RGB{N0f8}(RGB(ink)), RGB{N0f8}(RGB(paper)))
    end
end

function _render(effect::Halftone, img::AbstractMatrix{RGB{N0f8}})
    h, w = size(img)
    p = Float64(effect.cell)
    ca, sa = cos(effect.angle), sin(effect.angle)

    lum = Float64.(Gray.(img))
    out = Matrix{RGB{N0f8}}(undef, h, w)

    # A dot of radius r covers πr² of a p² cell, so full coverage needs
    # r = p/√π · √2 at the corners; going to p/√2 lets the blacks close up
    # completely instead of leaving pinholes between neighbouring dots.
    rmax = p / sqrt(2)

    # Lattice cell of a pixel, in lattice space.
    cell_of(x, y) = (floor(Int, (ca * x + sa * y) / p),
                     floor(Int, (-sa * x + ca * y) / p))

    # One pass to integrate the luminance each cell covers, so that the dot
    # stands for the whole area rather than for one pixel of it.
    sums = Dict{Tuple{Int,Int},Float64}()
    counts = Dict{Tuple{Int,Int},Int}()
    @inbounds for y in 1:h, x in 1:w
        k = cell_of(x, y)
        sums[k] = get(sums, k, 0.0) + lum[y, x]
        counts[k] = get(counts, k, 0) + 1
    end

    @inbounds for y in 1:h, x in 1:w
        # Into lattice space, where cells are axis-aligned.
        u = ca * x + sa * y
        v = -sa * x + ca * y

        k = cell_of(x, y)
        cu = (k[1] + 0.5) * p
        cv = (k[2] + 0.5) * p

        darkness = (1.0 - sums[k] / counts[k])^effect.gamma

        du, dv = u - cu, v - cv
        inked = if effect.shape === HalftoneShape.DOT
            sqrt(du * du + dv * dv) <= darkness * rmax
        else
            max(abs(du), abs(dv)) <= darkness * (p / 2)
        end
        out[y, x] = inked ? effect.ink : effect.paper
    end
    return out
end
