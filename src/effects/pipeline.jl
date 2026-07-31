"""
    Pipeline(effects...)

Compose one or more effects from left to right.

The pipeline itself is an [`AbstractEffect`](@ref), so it can be nested,
animated with [`render`](@ref), or passed to [`apply`](@ref). Appearance
conversion is performed once, after the complete pipeline.
"""
struct Pipeline{E <: Tuple} <: AbstractEffect
    effects::E

    function Pipeline(effects::Tuple)
        isempty(effects) &&
            throw(ArgumentError("Pipeline requires at least one effect"))
        all(effect -> effect isa AbstractEffect, effects) ||
            throw(ArgumentError("every Pipeline stage must be an AbstractEffect"))
        return new{typeof(effects)}(effects)
    end
end

Pipeline(effects::AbstractEffect...) = Pipeline(effects)

function _intrinsically_colored(pipeline::Pipeline)
    any(_intrinsically_colored, pipeline.effects)
end

function _render(pipeline::Pipeline, img::AbstractMatrix{RGB{N0f8}})
    current = img
    for effect in pipeline.effects
        current = _render(Base.inferencebarrier(effect), current)
    end
    return current
end
