"""
Root of the effect hierarchy.

An effect is an immutable value carrying its parameters; it holds no image.
Rendering goes through [`apply`](@ref), which requires a `_render` method for
each subtype.

This indirection is what lets `fit_cover`, `twilight` and the render loop be
written once for the whole catalogue.
"""
abstract type AbstractEffect end

"""
Apply `effect` to `img` and return the transformed image.

`appearance` selects the variant: [`Appearance.LIGHT`](@ref Appearance)
renders the effect as is, [`Appearance.DARK`](@ref Appearance) follows it with
[`twilight`](@ref). Geometry is identical either way — only colour changes.
"""
function apply(effect::AbstractEffect,
               img::AbstractMatrix{<:Colorant};
               appearance::Appearance.T = Appearance.LIGHT)
    out = _render(effect, RGB{N0f8}.(img))
    return appearance == Appearance.DARK ? twilight(out) : out
end

"""
Convert an intensity in `0:255` to an `N0f8` channel.

Every effect accumulates its averages as integers and comes back through
here. `round` breaks ties toward even, so a half-way average never drifts
consistently upward across a large flat area.
"""
@inline _u8(x::Real) = reinterpret(N0f8, round(UInt8, x))

"""
Raw render of an effect, without appearance handling.

This is the method each effect must implement; [`apply`](@ref) builds on it
and adds the twilight variant.
"""
function _render end
