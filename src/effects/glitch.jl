"""
Digital image corruption combining chromatic offsets, displaced horizontal
slices, and luminance-thresholded pixel sorting.

All distances are measured in pixels. `seed` makes slice selection stable;
`min_run` prevents very short bright runs from being reordered. Set the three
displacement controls to zero and `threshold = 1` for an identity transform.
"""
struct Glitch <: AbstractEffect
    channel_offset::Int
    slices::Int
    displacement::Int
    threshold::Float64
    min_run::Int
    seed::Int

    function Glitch(; channel_offset::Integer = 4,
            slices::Integer = 8, displacement::Integer = 18,
            threshold::Real = 0.55, min_run::Integer = 3,
            seed::Integer = 20260810)
        channel_offset >= 0 || throw(ArgumentError(
            "channel_offset must be non-negative, got $channel_offset"))
        slices >= 0 ||
            throw(ArgumentError("slices must be non-negative, got $slices"))
        displacement >= 0 || throw(ArgumentError(
            "displacement must be non-negative, got $displacement"))
        isfinite(threshold) && 0 <= threshold <= 1 || throw(ArgumentError(
            "threshold must be finite and between 0 and 1"))
        min_run >= 2 ||
            throw(ArgumentError("min_run must be >= 2, got $min_run"))
        return new(Int(channel_offset), Int(slices), Int(displacement),
            Float64(threshold), Int(min_run), Int(seed))
    end
end

_intrinsically_colored(::Glitch) = true

function _sort_glitch_runs!(row, threshold, min_run)
    first = firstindex(row)
    after = lastindex(row) + 1
    while first < after
        while first < after && Float64(Gray(row[first])) < threshold
            first += 1
        end
        last = first
        while last < after && Float64(Gray(row[last])) >= threshold
            last += 1
        end
        last - first >= min_run && sort!(view(row, first:(last - 1));
            by = pixel -> Float64(Gray(pixel)))
        first = last + 1
    end
    return row
end

function _chromatic_offset(img, offset)
    offset == 0 && return copy(img)
    height, width = size(img)
    return [RGB{N0f8}(
                red(img[y, mod1(x - offset, width)]),
                green(img[y, x]),
                blue(img[y, mod1(x + offset, width)]))
            for y in 1:height, x in 1:width]
end

function _displace_glitch_slices!(out, effect, rng)
    height, width = size(out)
    (effect.slices == 0 || effect.displacement == 0) && return out
    maximum_height = max(1, cld(height, 6))
    for _ in 1:(effect.slices)
        slice_height = rand(rng, 1:maximum_height)
        first_y = rand(rng, 1:(height - slice_height + 1))
        shift = rand(rng, (-effect.displacement):(effect.displacement))
        shift == 0 && continue
        for y in first_y:(first_y + slice_height - 1)
            source = copy(view(out, y, :))
            @inbounds for x in 1:width
                out[y, x] = source[mod1(x - shift, width)]
            end
        end
    end
    return out
end

function _render(effect::Glitch, img::AbstractMatrix{RGB{N0f8}})
    out = _chromatic_offset(img, effect.channel_offset)
    _displace_glitch_slices!(out, effect, StableRNG(effect.seed))
    for row in eachrow(out)
        _sort_glitch_runs!(row, effect.threshold, effect.min_run)
    end
    return out
end
