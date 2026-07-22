"""
Low-poly effect: a Delaunay triangulation with flat facets.

Seeds are scattered — dense along edges, sparse over flat areas — then
triangulated; each triangle is filled with a single colour. The result reads
as a landscape cut into crystal facets.

Because the seeds cluster where the image varies, facets are small on
silhouettes and large across the sky: the main shapes survive the
simplification.

How far that goes is `background`, not `detail`. It sets the share of seeds
drawn uniformly rather than from the edge map, and it is the parameter that
decides whether the result reads as an even mesh that merely tightens on the
subject (high) or as fine debris around large empty plates (low). `detail`
only sharpens the contrast *within* the edge term, and it peaks — see
[`_sample_points`](@ref).

This is the dual of [`Voronoi`](@ref) — same seeds, complementary tiling:
triangles here, polygonal cells there.
"""
struct LowPoly <: AbstractEffect
    "Number of seeds. The higher it is, the finer the facets."
    points::Int
    "How sharply seeds concentrate within the edge term. Peaks around 2."
    detail::Float64
    "Uniform floor, as a multiple of the mean edge weight. It carries `background / (1 + background)` of the draw."
    background::Float64
    "Seed of the point draw. Equal seeds give identical renders."
    seed::Int

    function LowPoly(; points::Integer = 4000,
                     detail::Real = 1.5,
                     background::Real = 5.0,
                     seed::Integer = 20260508)
        points >= 3 ||
            throw(ArgumentError("points must be >= 3, got $points"))
        detail >= 0 ||
            throw(ArgumentError("detail must be >= 0, got $detail"))
        background >= 0 ||
            throw(ArgumentError("background must be >= 0, got $background"))
        return new(Int(points), Float64(detail), Float64(background), Int(seed))
    end
end

function _render(effect::LowPoly, img::AbstractMatrix{RGB{N0f8}})
    h, w = size(img)
    rng = StableRNG(effect.seed)
    seeds = _sample_points(_edge_map(img), effect.points, rng, effect.detail;
                           background = effect.background)
    pts = unique(vcat(seeds, _border_points(h, w)))

    # `triangulate` randomises its insertion order: without an explicit RNG,
    # the traversal order of the triangles changes between calls, and with it
    # the colour of pixels sitting on a shared edge (painted by both
    # neighbouring facets). Passing our stream makes the render reproducible.
    tri = triangulate(pts; rng)
    out = Matrix{RGB{N0f8}}(undef, h, w)
    fill!(out, img[1, 1])  # safety net, should a pixel escape the sweep

    for T in each_solid_triangle(tri)
        i, j, k = triangle_vertices(T)
        a, b, c = get_point(tri, i), get_point(tri, j), get_point(tri, k)
        _fill_triangle!(out, img, a, b, c)
    end
    return out
end

"""
Flat colour of a facet: mean of the centroid and the three vertices.

Sampling the centroid as well keeps a facet straddling an edge from taking
the colour of one side only — the vertices themselves often sit *on* the
edge.
"""
function _facet_color(img::AbstractMatrix{RGB{N0f8}}, a, b, c)
    h, w = size(img)
    cx = (a[1] + b[1] + c[1]) / 3
    cy = (a[2] + b[2] + c[2]) / 3
    r = g = bl = 0
    for (x, y) in ((cx, cy), a, b, c)
        px = img[clamp(round(Int, y), 1, h), clamp(round(Int, x), 1, w)]
        r += Int(reinterpret(red(px)))
        g += Int(reinterpret(green(px)))
        bl += Int(reinterpret(blue(px)))
    end
    return RGB{N0f8}(_u8(r / 4), _u8(g / 4), _u8(bl / 4))
end

"""
Paint triangle `a`, `b`, `c` in a flat colour, sweeping its bounding box.

A pixel is kept when all three edge functions are non-negative, orientation
having been normalised beforehand. Since the test is `>= 0`, a pixel lying
exactly on a shared edge is painted by both neighbouring facets — redundant,
but never skipped: that is what guarantees there are no gaps between facets.
"""
function _fill_triangle!(out::Matrix{RGB{N0f8}},
                         img::AbstractMatrix{RGB{N0f8}}, a, b, c)
    h, w = size(out)
    area = (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1])
    area == 0 && return out
    if area < 0
        b, c = c, b  # counter-clockwise, so that "inside" means >= 0
    end

    color = _facet_color(img, a, b, c)
    xlo = clamp(floor(Int, min(a[1], b[1], c[1])), 1, w)
    xhi = clamp(ceil(Int, max(a[1], b[1], c[1])), 1, w)
    ylo = clamp(floor(Int, min(a[2], b[2], c[2])), 1, h)
    yhi = clamp(ceil(Int, max(a[2], b[2], c[2])), 1, h)

    @inbounds for x in xlo:xhi, y in ylo:yhi
        e1 = (b[1] - a[1]) * (y - a[2]) - (b[2] - a[2]) * (x - a[1])
        e1 < 0 && continue
        e2 = (c[1] - b[1]) * (y - b[2]) - (c[2] - b[2]) * (x - b[1])
        e2 < 0 && continue
        e3 = (a[1] - c[1]) * (y - c[2]) - (a[2] - c[2]) * (x - c[1])
        e3 < 0 && continue
        out[y, x] = color
    end
    return out
end
