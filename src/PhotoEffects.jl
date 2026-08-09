"""
    PhotoEffects

Turn a photograph into a stylised image — flat facets, polygonal cells,
painterly impasto, halftone screens — in a light or a twilight variant.

Each effect is a subtype of [`AbstractEffect`](@ref) carrying its parameters,
rendered through [`apply`](@ref):

```julia
using PhotoEffects
img = load("photo.jpg")
out = apply(Oil(radius = 9, passes = 2), fit_cover(img, 1920, 1080))
```
"""
module PhotoEffects

import Colors
using DelaunayTriangulation: triangulate, each_solid_triangle,
                             triangle_vertices, get_point
using DocStringExtensions
using DitherPunk: Bayer, FloydSteinberg, dither
using FixedPointNumbers: N0f8
using ImageCore
using ImageFiltering: imfilter, imgradients, mapwindow, Kernel, KernelFactors
using ImageTransformations: imresize, restrict
using ImageTransformations.Interpolations: Lanczos4OpenCV
using NearestNeighbors: KDTree, nn
using PrecompileTools: @compile_workload, @setup_workload
using Random: AbstractRNG
using StableRNGs: StableRNG
using Statistics: mean, median, quantile
using StaticArrays: SVector

include("docstrings.jl")
include("appearance.jl")
include("framing.jl")
include("seeding.jl")
include("effects/effect.jl")
include("effects/pipeline.jl")
include("effects/oil.jl")
include("effects/lowpoly.jl")
include("effects/voronoi.jl")
include("effects/posterize.jl")
include("effects/watercolour.jl")
include("effects/duotone.jl")
include("effects/halftone.jl")
include("effects/dither.jl")

export AbstractEffect, Dither, Duotone, Halftone, LowPoly, Oil, Pipeline,
       Posterize, Watercolour
export Voronoi, VoronoiLloyd, VoronoiStained
export apply, fit_cover, twilight
export Appearance, DitherMethod, HalftoneShape
export Seeding, Scatter, Given, sow, render, frame

@setup_workload begin
    img = rand(RGB{N0f8}, 32, 48)
    @compile_workload begin
        apply(Oil(radius = 2, passes = 1), img)
        apply(LowPoly(points = 20), img)
        apply(Voronoi(points = 20), img)
        apply(Posterize(levels = 4), img)
        apply(Watercolour(radius = 2), img)
        apply(Duotone(), img)
        apply(Halftone(cell = 4), img)
        apply(Dither(), img)
        apply(Pipeline(Posterize(levels = 4), Duotone()), img)
        apply(VoronoiStained(points = 20), img)
        apply(VoronoiLloyd(points = 20, iterations = 1), img)
        fit_cover(img, 16, 16)
        twilight(img)
    end
end

end # module
