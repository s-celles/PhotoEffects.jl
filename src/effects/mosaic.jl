"""
Square mosaic whose blocks take the mean colour beneath them.

`block` and `joint` are measured in output pixels and should scale with output
width. A positive joint draws the trailing edge of each tile in
`joint_color`; it must remain narrower than the block.
"""
struct PixelMosaic <: AbstractEffect
    "Square tile width and height in pixels."
    block::Int
    "Joint width in pixels."
    joint::Int
    "Colour painted between tiles."
    joint_color::RGB{N0f8}

    function PixelMosaic(; block::Integer = 12, joint::Integer = 0,
            joint_color::Colorant = RGB(0.92, 0.9, 0.85))
        block >= 1 ||
            throw(ArgumentError("block must be >= 1, got $block"))
        0 <= joint < block || throw(ArgumentError(
            "joint must lie in 0:$(block - 1), got $joint"))
        return new(Int(block), Int(joint), RGB{N0f8}(joint_color))
    end
end

_intrinsically_colored(effect::PixelMosaic) = effect.joint > 0

function _render(effect::PixelMosaic, img::AbstractMatrix{RGB{N0f8}})
    h, w = size(img)
    rows = cld(h, effect.block)
    columns = cld(w, effect.block)
    labels = Matrix{Int}(undef, h, w)
    counts = zeros(Int, rows * columns)

    @inbounds for x in 1:w, y in 1:h
        row = fld(y - 1, effect.block) + 1
        column = fld(x - 1, effect.block) + 1
        label = row + (column - 1) * rows
        labels[y, x] = label
        counts[label] += 1
    end
    out = _paint_voronoi(img, labels, counts)
    effect.joint == 0 && return out

    @inbounds for x in 1:w, y in 1:h
        tile_x = mod(x - 1, effect.block)
        tile_y = mod(y - 1, effect.block)
        if tile_x >= effect.block - effect.joint ||
           tile_y >= effect.block - effect.joint
            out[y, x] = effect.joint_color
        end
    end
    return out
end

"""
Regular honeycomb mosaic whose hexagonal cells take the mean colour beneath
them.

`cell` is the approximate hexagon radius in output pixels and should scale
with output width. A triangular lattice of centres is rasterised by nearest
membership, giving complete border coverage without polygon clipping.
"""
struct HexMosaic <: AbstractEffect
    "Approximate hexagon radius in pixels."
    cell::Int

    function HexMosaic(; cell::Integer = 10)
        cell >= 2 ||
            throw(ArgumentError("cell must be >= 2, got $cell"))
        return new(Int(cell))
    end
end

function _hex_centres((h, w), radius)
    horizontal = 1.5 * radius
    vertical = sqrt(3) * radius
    centres = SVector{2, Float64}[]
    column = 0
    x = 1.0 - radius
    while x <= w + radius
        offset = isodd(column) ? vertical / 2 : 0.0
        y = 1.0 - radius - vertical + offset
        while y <= h + radius + vertical
            push!(centres, SVector(x, y))
            y += vertical
        end
        column += 1
        x += horizontal
    end
    return centres
end

function _render(effect::HexMosaic, img::AbstractMatrix{RGB{N0f8}})
    centres = _hex_centres(size(img), effect.cell)
    labels, counts = _voronoi_labels(centres, size(img))
    return _paint_voronoi(img, labels, counts)
end
