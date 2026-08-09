"""
Soft abstract colour blobs derived from the source image's dominant palette.

The palette is extracted without using pixel positions, so images with the
same colour distribution produce the same abstraction for a fixed `seed`.
`radius` is the Gaussian blob radius in output pixels. `colors` controls
palette size, `blobs` controls the number of overlaid fields, and `iterations`
controls deterministic colour clustering.
"""
struct Blobs <: AbstractEffect
    colors::Int
    blobs::Int
    radius::Float64
    iterations::Int
    seed::Int

    function Blobs(; colors::Integer = 4, blobs::Integer = 7,
            radius::Real = 120, iterations::Integer = 6,
            seed::Integer = 20260508)
        colors >= 2 ||
            throw(ArgumentError("colors must be >= 2, got $colors"))
        blobs >= 1 ||
            throw(ArgumentError("blobs must be >= 1, got $blobs"))
        isfinite(radius) && radius > 0 ||
            throw(ArgumentError("radius must be finite and positive"))
        iterations >= 1 || throw(ArgumentError(
            "iterations must be >= 1, got $iterations"))
        return new(Int(colors), Int(blobs), Float64(radius), Int(iterations),
            Int(seed))
    end
end

function _dominant_palette(img, count, iterations)
    samples = RGB{Float64}.(vec(img))
    order = sortperm(samples;
        by = color -> (Float64(Gray(color)), color.r, color.g, color.b))
    centres = [samples[order[round(Int, position)]]
               for position in range(1, length(samples); length = count)]

    for _ in 1:iterations
        sums = zeros(Float64, count, 3)
        totals = zeros(Int, count)
        @inbounds for sample in samples
            cluster = argmin(((sample.r - centre.r)^2 +
                              (sample.g - centre.g)^2 +
                              (sample.b - centre.b)^2 for centre in centres))
            sums[cluster, 1] += sample.r
            sums[cluster, 2] += sample.g
            sums[cluster, 3] += sample.b
            totals[cluster] += 1
        end
        @inbounds for cluster in eachindex(centres)
            totals[cluster] == 0 && continue
            centres[cluster] = RGB(
                sums[cluster, 1] / totals[cluster],
                sums[cluster, 2] / totals[cluster],
                sums[cluster, 3] / totals[cluster])
        end
    end
    sort!(centres;
        by = color -> (Float64(Gray(color)), color.r, color.g, color.b))
    return centres
end

function _render(effect::Blobs, img::AbstractMatrix{RGB{N0f8}})
    palette = _dominant_palette(img, effect.colors, effect.iterations)
    rng = StableRNG(effect.seed)
    height, width = size(img)
    centres = [(1 + (width - 1) * rand(rng),
                   1 + (height - 1) * rand(rng),
                   rand(rng, eachindex(palette))) for _ in 1:(effect.blobs)]
    out = Matrix{RGB{N0f8}}(undef, height, width)
    denominator = 2effect.radius^2

    @inbounds for x in 1:width, y in 1:height
        progress = height == 1 ? 0.5 : (y - 1) / (height - 1)
        first_color, last_color = palette[1], palette[end]
        red_value = (1 - progress) * first_color.r + progress * last_color.r
        green_value = (1 - progress) * first_color.g + progress * last_color.g
        blue_value = (1 - progress) * first_color.b + progress * last_color.b
        for (centre_x, centre_y, palette_index) in centres
            weight = 0.7 * exp(-((x - centre_x)^2 +
                           (y - centre_y)^2) / denominator)
            colour = palette[palette_index]
            red_value = (1 - weight) * red_value + weight * colour.r
            green_value = (1 - weight) * green_value + weight * colour.g
            blue_value = (1 - weight) * blue_value + weight * colour.b
        end
        out[y, x] = RGB{N0f8}(red_value, green_value, blue_value)
    end
    return out
end
