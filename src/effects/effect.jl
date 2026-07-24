"""
Root of the effect hierarchy.

An effect is an immutable value carrying its parameters; it holds no image.
Rendering goes through [`apply`](@ref), which requires a `_render` method for
each subtype.

This indirection is what lets `fit_cover`, `twilight` and the render loop be
written once for the whole catalogue.
"""
abstract type AbstractEffect end

function Base.:(==)(a::T, b::T) where T <: AbstractEffect
    all(getfield(a, f) == getfield(b, f) for f in fieldnames(T))
end

function Base.hash(a::T, h::UInt) where T <: AbstractEffect
    foldr(hash, (getfield(a, f) for f in fieldnames(T)), init=hash(T, h))
end

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

"""
    frame(f, img, t)

Isolated frame generation without shared state.
"""
function frame(f, img, t)
    return apply(f(t), img)
end

"""
    render(f, img, times)

Lazy evaluation of a sequence of frames. `f` is a function `t -> AbstractEffect`.
Returns an iterator of frames.
"""
function render(f, img, times)
    return RenderSequence(f, img, times)
end

struct RenderSequence{F, I, T}
    f::F
    img::I
    times::T
end

Base.length(r::RenderSequence) = length(r.times)
Base.eltype(::Type{<:RenderSequence}) = Matrix{RGB{N0f8}}

function Base.iterate(r::RenderSequence, state=nothing)
    it = state === nothing ? iterate(r.times) : iterate(r.times, state)
    it === nothing && return nothing
    t, next_state = it
    return (frame(r.f, r.img, t), next_state)
end
