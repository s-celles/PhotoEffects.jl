"""
Deterministic photographic grain or paper-like luminance texture.

`amount` is the maximum signed channel displacement in `[0, 1]`. By default a
single luminance perturbation is shared by all channels; set `chromatic=true`
for independent colour noise. `amount=0` is an exact identity operation.
"""
struct Grain <: AbstractEffect
    amount::Float64
    chromatic::Bool
    seed::Int

    function Grain(; amount::Real = 0.06, chromatic::Bool = false,
            seed::Integer = 20260508)
        isfinite(amount) && 0 <= amount <= 1 ||
            throw(ArgumentError("amount must lie in [0, 1], got $amount"))
        return new(Float64(amount), chromatic, Int(seed))
    end
end

function _render(effect::Grain, img::AbstractMatrix{RGB{N0f8}})
    effect.amount == 0 && return copy(img)
    rng = StableRNG(effect.seed)
    out = similar(img)
    @inbounds for index in eachindex(img)
        colour = RGB{Float64}(img[index])
        red_noise = effect.amount * (2rand(rng) - 1)
        green_noise = effect.chromatic ? effect.amount * (2rand(rng) - 1) :
                      red_noise
        blue_noise = effect.chromatic ? effect.amount * (2rand(rng) - 1) :
                     red_noise
        out[index] = RGB{N0f8}(
            clamp(colour.r + red_noise, 0, 1),
            clamp(colour.g + green_noise, 0, 1),
            clamp(colour.b + blue_noise, 0, 1))
    end
    return out
end
