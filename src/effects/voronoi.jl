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
    result at the cost of delicate clipping at the image border.
    `VoronoiStained` extracts leading from raster label boundaries, while
    `VoronoiLloyd` measures raster centroids, so all three variants share the
    same border and coverage semantics.
"""
struct Voronoi{S <: Seeding} <: AbstractEffect
    seeding::S

    function Voronoi(seeding::Seeding)
        return new{typeof(seeding)}(seeding)
    end

    function Voronoi(; points::Integer = 3000,
            detail::Real = 1.4,
            background::Real = 5.0,
            seed::Integer = 20260508)
        return new{Scatter}(Scatter(; points, detail, background, seed))
    end
end

function _render(effect::Voronoi, img::AbstractMatrix{RGB{N0f8}})
    g = sow(effect.seeding, img)
    if length(g.points) < 1
        throw(ArgumentError("Voronoi requires at least 1 point"))
    end
    labels, counts = _voronoi_labels(g.points, size(img))
    return _paint_voronoi(img, labels, counts)
end

function _voronoi_labels(seeds, (h, w))
    tree = KDTree(reduce(hcat, seeds))
    n = length(seeds)
    counts = zeros(Int, n)
    labels = Matrix{Int}(undef, h, w)

    @inbounds for x in 1:w, y in 1:h
        idx, _ = nn(tree, SVector(Float64(x), Float64(y)))
        labels[y, x] = idx
        counts[idx] += 1
    end
    return labels, counts
end

function _paint_voronoi(img::AbstractMatrix{RGB{N0f8}}, labels, counts)
    h, w = size(img)
    n = length(counts)
    sums = zeros(Int, n, 3)
    @inbounds for i in eachindex(labels)
        idx = labels[i]
        px = img[i]
        sums[idx, 1] += Int(reinterpret(red(px)))
        sums[idx, 2] += Int(reinterpret(green(px)))
        sums[idx, 3] += Int(reinterpret(blue(px)))
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

"""
Voronoi cells separated by dark or coloured joints.

`joint` is the joint width in pixels at the rendered resolution. Set it to
zero to recover an ordinary [`Voronoi`](@ref) render.
"""
struct VoronoiStained{S <: Seeding} <: AbstractEffect
    seeding::S
    joint::Int
    joint_color::RGB{N0f8}

    function VoronoiStained(seeding::Seeding;
            joint::Integer = 1,
            joint_color::Colorant = RGB(0.04, 0.04, 0.05))
        joint >= 0 ||
            throw(ArgumentError("joint must be >= 0, got $joint"))
        return new{typeof(seeding)}(
            seeding, Int(joint), RGB{N0f8}(joint_color))
    end
end

_intrinsically_colored(::VoronoiStained) = true

function VoronoiStained(; points::Integer = 3000,
        detail::Real = 1.4,
        background::Real = 5.0,
        seed::Integer = 20260508,
        joint::Integer = 1,
        joint_color::Colorant = RGB(0.04, 0.04, 0.05))
    return VoronoiStained(
        Scatter(; points, detail, background, seed);
        joint, joint_color)
end

function _render(effect::VoronoiStained, img::AbstractMatrix{RGB{N0f8}})
    seeds = sow(effect.seeding, img).points
    isempty(seeds) &&
        throw(ArgumentError("VoronoiStained requires at least 1 point"))
    labels, counts = _voronoi_labels(seeds, size(img))
    out = _paint_voronoi(img, labels, counts)
    effect.joint == 0 && return out

    h, w = size(out)
    boundary = falses(h, w)
    @inbounds for x in 1:w, y in 1:h
        label = labels[y, x]
        boundary[y, x] = (x < w && labels[y, x + 1] != label) ||
                         (y < h && labels[y + 1, x] != label)
    end
    radius = effect.joint - 1
    @inbounds for x in 1:w, y in 1:h
        if any(boundary[max(1, y - radius):min(h, y + radius),
            max(1, x - radius):min(w, x + radius)])
            out[y, x] = effect.joint_color
        end
    end
    return out
end

"""
Centroidal Voronoi effect produced by Lloyd relaxation.

`iterations` moves every seed to the centroid of its raster cell. Higher
values make cell areas progressively more even while preserving the
deterministic initial draw.
"""
struct VoronoiLloyd{S <: Seeding} <: AbstractEffect
    seeding::S
    iterations::Int

    function VoronoiLloyd(seeding::Seeding; iterations::Integer = 3)
        iterations >= 0 ||
            throw(ArgumentError("iterations must be >= 0, got $iterations"))
        return new{typeof(seeding)}(seeding, Int(iterations))
    end
end

function VoronoiLloyd(; points::Integer = 3000,
        detail::Real = 1.4,
        background::Real = 5.0,
        seed::Integer = 20260508,
        iterations::Integer = 3)
    return VoronoiLloyd(
        Scatter(; points, detail, background, seed);
        iterations)
end

function _lloyd_points(effect::VoronoiLloyd, img)
    seeds = copy(sow(effect.seeding, img).points)
    isempty(seeds) &&
        throw(ArgumentError("VoronoiLloyd requires at least 1 point"))
    h, w = size(img)
    for _ in 1:(effect.iterations)
        labels, counts = _voronoi_labels(seeds, (h, w))
        sums = zeros(Float64, length(seeds), 2)
        @inbounds for x in 1:w, y in 1:h
            idx = labels[y, x]
            sums[idx, 1] += x
            sums[idx, 2] += y
        end
        @inbounds for i in eachindex(seeds)
            counts[i] == 0 && continue
            seeds[i] = SVector(sums[i, 1] / counts[i],
                sums[i, 2] / counts[i])
        end
    end
    return seeds
end

function _voronoi_cell_counts(effect::VoronoiLloyd, img)
    _, counts = _voronoi_labels(_lloyd_points(effect, img), size(img))
    return counts
end

function _render(effect::VoronoiLloyd, img::AbstractMatrix{RGB{N0f8}})
    labels, counts = _voronoi_labels(_lloyd_points(effect, img), size(img))
    return _paint_voronoi(img, labels, counts)
end
