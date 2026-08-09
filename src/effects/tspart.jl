"""
Single-line travelling-salesman art over darkness-weighted stipples.

`points` is a resolution-relative count. Stipples are drawn without
replacement according to source darkness, connected by a deterministic
nearest-neighbour tour, then improved by `optimize` 2-opt passes. `width` is
the line thickness in output pixels.
"""
struct TspArt <: AbstractEffect
    points::Int
    width::Int
    detail::Float64
    background_weight::Float64
    optimize::Int
    seed::Int
    ink::RGB{N0f8}
    paper::RGB{N0f8}

    function TspArt(; points::Integer = 600, width::Integer = 1,
            detail::Real = 1.4, background_weight::Real = 0.05,
            optimize::Integer = 1, seed::Integer = 20260508,
            ink::Colorant = RGB(0.05, 0.07, 0.09),
            paper::Colorant = RGB(0.96, 0.94, 0.88))
        points >= 2 ||
            throw(ArgumentError("points must be >= 2, got $points"))
        width >= 1 ||
            throw(ArgumentError("width must be >= 1, got $width"))
        isfinite(detail) && detail > 0 ||
            throw(ArgumentError("detail must be finite and positive"))
        isfinite(background_weight) && background_weight >= 0 || throw(
            ArgumentError("background_weight must be finite and non-negative"))
        optimize >= 0 ||
            throw(ArgumentError("optimize must be >= 0, got $optimize"))
        return new(Int(points), Int(width), Float64(detail),
            Float64(background_weight), Int(optimize), Int(seed),
            RGB{N0f8}(ink), RGB{N0f8}(paper))
    end
end

_intrinsically_colored(::TspArt) = true

function _tsp_stipples(effect::TspArt, img)
    height, width = size(img)
    effect.points <= length(img) || throw(ArgumentError(
        "points=$(effect.points) exceeds the $(length(img)) available pixels"))
    darkness = 1 .- Float64.(Gray.(img))
    maximum(darkness) > 0 || return SVector{2, Float64}[]
    weights = darkness .^ effect.detail
    floor_weight = effect.background_weight * mean(weights)
    rng = StableRNG(effect.seed)
    keys = Vector{Float64}(undef, length(img))
    @inbounds for index in eachindex(keys)
        weight = weights[index] + floor_weight
        keys[index] = weight > 0 ? log(rand(rng)) / weight : -Inf
    end
    selected = partialsortperm(keys, 1:(effect.points); rev = true)
    return [SVector{2, Float64}(cld(index, height), mod1(index, height))
            for index in selected]
end

@inline _squared_distance(first, second) = (first[1] - second[1])^2 +
                                           (first[2] - second[2])^2

function _tsp_tour(points, optimize)
    isempty(points) && return copy(points)
    count = length(points)
    used = falses(count)
    order = Vector{Int}(undef, count)
    order[1] = 1
    used[1] = true
    for position in 2:count
        current = order[position - 1]
        best = 0
        best_distance = Inf
        for candidate in eachindex(points)
            used[candidate] && continue
            distance = _squared_distance(points[current], points[candidate])
            if distance < best_distance
                best, best_distance = candidate, distance
            end
        end
        order[position] = best
        used[best] = true
    end
    tour = points[order]

    count < 4 && return tour
    for _ in 1:optimize
        improved = false
        for first_index in 1:(count - 2)
            second_index = first_index + 1
            for third_index in (second_index + 1):(count - 1)
                fourth_index = third_index + 1
                before = _squared_distance(
                    tour[first_index], tour[second_index]) +
                         _squared_distance(
                    tour[third_index], tour[fourth_index])
                after = _squared_distance(
                    tour[first_index], tour[third_index]) +
                        _squared_distance(
                    tour[second_index], tour[fourth_index])
                if after < before
                    reverse!(@view tour[second_index:third_index])
                    improved = true
                end
            end
        end
        improved || break
    end
    return tour
end

function _render(effect::TspArt, img::AbstractMatrix{RGB{N0f8}})
    points = _tsp_stipples(effect, img)
    height, image_width = size(img)
    out = fill(effect.paper, height, image_width)
    length(points) < 2 && return out
    tour = _tsp_tour(points, effect.optimize)
    radius = effect.width / 2
    reach = ceil(Int, radius)

    @inbounds for index in eachindex(tour)
        first = tour[index]
        second = tour[mod1(index + 1, length(tour))]
        first_x, first_y = first
        second_x, second_y = second
        minimum_x = max(1, floor(Int, min(first_x, second_x)) - reach)
        maximum_x = min(image_width,
            ceil(Int, max(first_x, second_x)) + reach)
        minimum_y = max(1, floor(Int, min(first_y, second_y)) - reach)
        maximum_y = min(height,
            ceil(Int, max(first_y, second_y)) + reach)
        for x in minimum_x:maximum_x
            for y in minimum_y:maximum_y
                _segment_distance_squared(x, y, first_x, first_y,
                    second_x, second_y) <= radius^2 || continue
                out[y, x] = effect.ink
            end
        end
    end
    return out
end
