# ITU-R BT.601 luminance weights, in thousandths. Keeping them integral makes
# the variance comparison exact, hence independent of summation order.
const _LUMA = (299, 587, 114)

"""
Oil-painting effect, via the Kuwahara filter.

For every pixel, the four overlapping quadrants around it are evaluated; the
most homogeneous one — the one whose luminance varies least — wins, and the
pixel takes its mean colour.

That choice is what produces the look: in the middle of a flat area the
quadrants are equivalent and the region smooths into impasto, but on an edge
only the quadrant on the correct side is homogeneous, so colour never crosses
the boundary. A blur, by contrast, would average both sides.

Unlike the tessellation effects, the geometry is not imposed on the image: it
emerges from it, and the patches follow the shapes.
"""
struct Oil <: AbstractEffect
    "Brush size, in pixels. Must scale with the output width."
    radius::Int
    "How many times the filter is applied in succession."
    passes::Int

    function Oil(; radius::Integer = 9, passes::Integer = 2)
        radius >= 0 ||
            throw(ArgumentError("radius must be >= 0, got $radius"))
        passes >= 1 ||
            throw(ArgumentError("passes must be >= 1, got $passes"))
        return new(Int(radius), Int(passes))
    end
end

function _render(effect::Oil, img::AbstractMatrix{RGB{N0f8}})
    effect.radius == 0 && return collect(img)
    out = img
    for _ in 1:(effect.passes)
        out = _kuwahara_pass(out, effect.radius)
    end
    return out
end

"""
Integer channels of `img`, padded by `r` pixels through edge replication.

Returns an `(h + 2r) × (w + 2r) × 3` array of values in `0:255`. Working in
`Int` rather than `N0f8` avoids any overflow in the cumulative sums that
follow.
"""
function _padded_channels(img::AbstractMatrix{RGB{N0f8}}, r::Int)
    h, w = size(img)
    a = Array{Int}(undef, h + 2r, w + 2r, 3)
    @inbounds for j in 1:(w + 2r), i in 1:(h + 2r)
        c = img[clamp(i - r, 1, h), clamp(j - r, 1, w)]
        a[i, j, 1] = reinterpret(red(c))
        a[i, j, 2] = reinterpret(green(c))
        a[i, j, 3] = reinterpret(blue(c))
    end
    return a
end

"""
Integral image of `a`, with a leading row and column of zeros.

The sum over any rectangle then reads in four lookups, hence in constant
time: the cost of the filter does not depend on the radius.
"""
function _integral(a::AbstractMatrix{Int})
    h, w = size(a)
    ii = zeros(Int, h + 1, w + 1)
    @inbounds for j in 1:w, i in 1:h
        ii[i + 1, j + 1] = a[i, j] + ii[i, j + 1] + ii[i + 1, j] - ii[i, j]
    end
    return ii
end

"""
Sum over the `k`×`k` square anchored at `(i + top, j + left)` in the integral.
"""
@inline function _box(ii::Matrix{Int}, i::Int, j::Int,
                      top::Int, left::Int, k::Int)
    @inbounds return (ii[i + top + k, j + left + k]
                      - ii[i + top, j + left + k]
                      - ii[i + top + k, j + left]
                      + ii[i + top, j + left])
end

function _kuwahara_pass(img::AbstractMatrix{RGB{N0f8}}, r::Int)
    h, w = size(img)
    a = _padded_channels(img, r)

    lum = similar(a, Int, size(a, 1), size(a, 2))
    @inbounds for j in axes(lum, 2), i in axes(lum, 1)
        lum[i, j] = (a[i, j, 1] * _LUMA[1] + a[i, j, 2] * _LUMA[2] +
                     a[i, j, 3] * _LUMA[3]) ÷ 1000
    end

    int_lum = _integral(lum)
    int_lum2 = _integral(lum .* lum)
    int_rgb = ntuple(c -> _integral(view(a, :, :, c)), 3)

    k = r + 1
    n = k * k
    offsets = ((0, 0), (0, r), (r, 0), (r, r))
    out = Matrix{RGB{N0f8}}(undef, h, w)

    @inbounds for j in 1:w, i in 1:h
        best_score = typemax(Int)
        best = 1
        for q in 1:4
            top, left = offsets[q]
            s = _box(int_lum, i, j, top, left, k)
            s2 = _box(int_lum2, i, j, top, left, k)
            # variance × n² — integral, so the comparison is exact and needs
            # no division. Strict `<`: on a tie the first quadrant wins.
            score = s2 * n - s * s
            if score < best_score
                best_score = score
                best = q
            end
        end
        top, left = offsets[best]
        out[i, j] = RGB{N0f8}(_u8(_box(int_rgb[1], i, j, top, left, k) / n),
                              _u8(_box(int_rgb[2], i, j, top, left, k) / n),
                              _u8(_box(int_rgb[3], i, j, top, left, k) / n))
    end
    return out
end
