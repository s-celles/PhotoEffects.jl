"""
Watercolour washes with soft pigment bleeding, deterministic granulation and
paper lightening.

`radius` is the wet-brush radius in pixels and should scale with output width.
`bleeding` mixes neighbouring pigment into each wash, `granulation` controls
fine pigment variation, and `paper` lets the white support show through.
Random granulation is reproducible for a given `seed`.
"""
struct Watercolour <: AbstractEffect
    "Wet-brush radius in pixels."
    radius::Int
    "Fraction of neighbouring pigment mixed into the wash."
    bleeding::Float64
    "Strength of deterministic pigment granulation."
    granulation::Float64
    "Fraction of white paper visible through the pigment."
    paper::Float64
    "Seed controlling the paper and pigment texture."
    seed::Int

    function Watercolour(; radius::Integer = 5, bleeding::Real = 0.45,
            granulation::Real = 0.08, paper::Real = 0.12,
            seed::Integer = 1)
        radius >= 1 ||
            throw(ArgumentError("radius must be >= 1, got $radius"))
        0 <= bleeding <= 1 || throw(ArgumentError(
            "bleeding must lie in [0, 1], got $bleeding"))
        0 <= granulation <= 1 || throw(ArgumentError(
            "granulation must lie in [0, 1], got $granulation"))
        0 <= paper <= 1 ||
            throw(ArgumentError("paper must lie in [0, 1], got $paper"))
        return new(Int(radius), Float64(bleeding), Float64(granulation),
            Float64(paper), Int(seed))
    end
end

function _render(effect::Watercolour, img::AbstractMatrix{RGB{N0f8}})
    blurred = effect.bleeding == 0 ? img :
              imfilter(img, Kernel.gaussian(effect.radius / 2))
    rng = StableRNG(effect.seed)
    out = similar(img)

    @inbounds for index in eachindex(img)
        source = RGB{Float64}(img[index])
        spread = RGB{Float64}(blurred[index])
        texture = 1 + effect.granulation * (2rand(rng) - 1)

        function channel(a, b)
            wash = (1 - effect.bleeding) * a + effect.bleeding * b
            pigment = clamp(wash * texture, 0, 1)
            pigment + effect.paper * (1 - pigment)
        end
        out[index] = RGB{N0f8}(
            channel(source.r, spread.r),
            channel(source.g, spread.g),
            channel(source.b, spread.b))
    end
    return out
end
