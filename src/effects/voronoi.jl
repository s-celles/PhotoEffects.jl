"""
Voronoi effect: flat-coloured polygonal cells.

Seeds are scattered as in [`LowPoly`](@ref), but each pixel is attached to
its **nearest** seed, and every resulting cell takes the mean colour of the
photo beneath it.

The look is more "pebbles" or "stained glass" than low-poly: cells are
rounded convex polygons rather than triangles, and their colour is a genuine
area average rather than a four-point sample — gradients survive better.

The two effects are duals: the Voronoi diagram is the dual of the Delaunay
triangulation of the same seeds.

!!! note "Why there are no explicit polygons"
    The tiling is rasterised by nearest-seed membership, which *is* the
    definition of a Voronoi cell. Computing the polygons (via
    `DelaunayTriangulation.voronoi`) and rasterising them would give the same
    result at the cost of delicate clipping at the image border. Explicit
    geometry will become necessary to stroke the leading of a stained-glass
    render, or for Lloyd relaxation.
"""
struct Voronoi <: AbstractEffect
    "Number of seeds, i.e. the number of cells."
    points::Int
    "How sharply seeds concentrate within the edge term. Peaks around 2."
    detail::Float64
    "Uniform floor, as a multiple of the mean edge weight. It carries `background / (1 + background)` of the draw."
    background::Float64
    "Seed of the point draw. Equal seeds give identical renders."
    seed::Int

    function Voronoi(; points::Integer = 3000,
                     detail::Real = 1.4,
                     background::Real = 5.0,
                     seed::Integer = 20260508)
        points >= 1 ||
            throw(ArgumentError("points must be >= 1, got $points"))
        detail >= 0 ||
            throw(ArgumentError("detail must be >= 0, got $detail"))
        background >= 0 ||
            throw(ArgumentError("background must be >= 0, got $background"))
        return new(Int(points), Float64(detail), Float64(background), Int(seed))
    end
end

function _render(effect::Voronoi, img::AbstractMatrix{RGB{N0f8}})
    h, w = size(img)
    rng = StableRNG(effect.seed)
    seeds = _sample_points(_edge_map(img), effect.points, rng, effect.detail;
                           background = effect.background)

    tree = KDTree(reduce(hcat, [SVector(p[1], p[2]) for p in seeds]))
    n = length(seeds)

    sums = zeros(Int, n, 3)
    counts = zeros(Int, n)
    labels = Matrix{Int}(undef, h, w)

    @inbounds for x in 1:w, y in 1:h
        idx, _ = nn(tree, SVector(Float64(x), Float64(y)))
        labels[y, x] = idx
        px = img[y, x]
        sums[idx, 1] += Int(reinterpret(red(px)))
        sums[idx, 2] += Int(reinterpret(green(px)))
        sums[idx, 3] += Int(reinterpret(blue(px)))
        counts[idx] += 1
    end

    palette = Vector{RGB{N0f8}}(undef, n)
    @inbounds for i in 1:n
        c = max(counts[i], 1)
        palette[i] = RGB{N0f8}(_u8(sums[i, 1] / c),
                               _u8(sums[i, 2] / c),
                               _u8(sums[i, 3] / c))
    end

    out = Matrix{RGB{N0f8}}(undef, h, w)
    @inbounds for i in eachindex(labels)
        out[i] = palette[labels[i]]
    end
    return out
end
