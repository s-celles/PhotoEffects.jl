"""Dithering algorithm used by [`PhotoEffects.Dither`](@ref)."""
module DitherMethod
@enum T begin
    FLOYD_STEINBERG
    BAYER
end
end

"""
Palette dithering through Floyd–Steinberg error diffusion or an ordered Bayer
matrix.

With no explicit `palette`, `levels` creates an evenly spaced grayscale
palette. Supplying two to 256 colours preserves those colours exactly and
makes the effect intrinsically coloured for grayscale inputs.
"""
struct Dither <: AbstractEffect
    "Diffusion or ordered dithering algorithm."
    method::DitherMethod.T
    "Number of generated grayscale palette entries."
    levels::Int
    "Explicit output palette, or `nothing` for generated grayscale."
    palette::Union{Nothing, Vector{RGB{N0f8}}}

    function Dither(; method::DitherMethod.T = DitherMethod.FLOYD_STEINBERG,
            levels::Integer = 2,
            palette::Union{Nothing, AbstractVector{<:Colorant}} = nothing)
        2 <= levels <= 256 || throw(ArgumentError(
            "levels must lie in 2:256, got $levels"))
        if !isnothing(palette)
            2 <= length(palette) <= 256 || throw(ArgumentError(
                "palette must contain between 2 and 256 colours"))
        end
        colors = isnothing(palette) ? nothing : RGB{N0f8}.(RGB.(palette))
        return new(method, Int(levels), colors)
    end
end

_intrinsically_colored(effect::Dither) = !isnothing(effect.palette)

function _dither_palette(effect::Dither)
    !isnothing(effect.palette) && return effect.palette
    return [RGB{N0f8}(value, value, value)
            for value in range(0, 1; length = effect.levels)]
end

function _render(effect::Dither, img::AbstractMatrix{RGB{N0f8}})
    algorithm = effect.method === DitherMethod.FLOYD_STEINBERG ?
                FloydSteinberg() : Bayer()
    return Matrix(dither(
        RGB{N0f8}, img, algorithm, _dither_palette(effect)))
end
