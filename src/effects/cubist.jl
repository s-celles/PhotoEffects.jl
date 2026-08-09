"""
Irregular convex polygon mosaic with deterministic colour displacement.

The geometry is a sparse Voronoi tessellation, producing the large angular
planes associated with a cubist treatment. `shift` controls independent
per-cell RGB channel displacement as a fraction in `[0, 1]`; zero recovers
the corresponding [`Voronoi`](@ref) rendering exactly. `seed` controls both
the default geometry and the colour variation.
"""
struct Cubist{S <: Seeding} <: AbstractEffect
    seeding::S
    shift::Float64
    seed::Int

    function Cubist(seeding::Seeding; shift::Real = 0.15,
            seed::Integer = 20260508)
        isfinite(shift) && 0 <= shift <= 1 ||
            throw(ArgumentError("shift must lie in [0, 1], got $shift"))
        return new{typeof(seeding)}(seeding, Float64(shift), Int(seed))
    end
end

function Cubist(; points::Integer = 120, shift::Real = 0.15,
        seed::Integer = 20260508)
    seeding = Scatter(; points, detail = 0, background = 1, seed)
    return Cubist(seeding; shift, seed)
end

function _render(effect::Cubist, img::AbstractMatrix{RGB{N0f8}})
    seeds = sow(effect.seeding, img).points
    isempty(seeds) && throw(ArgumentError("Cubist requires at least 1 point"))
    labels, counts = _voronoi_labels(seeds, size(img))
    out = _paint_voronoi(img, labels, counts)
    effect.shift == 0 && return out

    rng = StableRNG(effect.seed)
    base_palette = fill(RGB{N0f8}(0, 0, 0), length(counts))
    seen = falses(length(counts))
    @inbounds for index in eachindex(labels)
        label = labels[index]
        if !seen[label]
            base_palette[label] = out[index]
            seen[label] = true
        end
    end
    palette = Vector{RGB{N0f8}}(undef, length(counts))
    @inbounds for label in eachindex(palette)
        colour = RGB{Float64}(base_palette[label])
        displacement() = effect.shift * (2rand(rng) - 1)
        palette[label] = RGB{N0f8}(
            clamp(colour.r + displacement(), 0, 1),
            clamp(colour.g + displacement(), 0, 1),
            clamp(colour.b + displacement(), 0, 1))
    end
    @inbounds for index in eachindex(out)
        out[index] = palette[labels[index]]
    end
    return out
end
