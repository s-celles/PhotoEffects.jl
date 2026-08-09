# Guide

## Choosing an effect

| Effect | Result |
|---|---|
| `LowPoly` | Delaunay triangles filled with sampled colours |
| `Voronoi` | Polygonal cells painted from area averages |
| `VoronoiStained` | Voronoi cells separated by coloured joints |
| `VoronoiLloyd` | Relaxed Voronoi cells with more even areas |
| `Cubist` | Large irregular convex planes with shifted colours |
| `HexMosaic` | Regular honeycomb cells filled by area averages |
| `PixelMosaic` | Square mean-colour blocks with optional joints |
| `Oil` | Edge-preserving Kuwahara painting |
| `Posterize` | Quantized colour bands with optional outlines |
| `Watercolour` | Soft bleeding washes with paper and granulation |
| `Duotone` | Luminance mapped onto a colour ramp |
| `Halftone` | Tone represented by marks on a rotated screen |
| `Dither` | Palette reduction through diffusion or a Bayer matrix |

```julia
effect = LowPoly(points = 3_000, seed = 42)
result = apply(effect, img)
```

Regular mosaics express their cell size in output pixels:

```julia
honeycomb = apply(HexMosaic(cell=10), img)
tiles = apply(PixelMosaic(
    block=12, joint=1, joint_color=RGB("#eee5d5")), img)
```

`Cubist` uses a deliberately sparse tessellation and reproducible per-cell
colour displacement. Set `shift=0` to retain the geometry with unshifted mean
colours:

```julia
abstracted = apply(Cubist(points=120, shift=0.15, seed=42), img)
```

Watercolour texture is deterministic and its radius is measured in pixels:

```julia
painted = apply(Watercolour(
    radius=6, bleeding=0.5, granulation=0.08, paper=0.12, seed=42), img)
```

`Dither()` generates a binary grayscale palette by default. Choose ordered
dithering or supply a colour palette when a graphic colour treatment is
needed:

```julia
retro = apply(Dither(
    method=DitherMethod.BAYER,
    palette=[RGB("#172038"), RGB("#f4d58d")]), img)
```

## Composing effects

`Pipeline` applies effects from left to right while performing appearance and
colour-space conversion only once:

```julia
effect = Pipeline(Oil(radius = 3), Posterize(levels = 7), Duotone())
result = apply(effect, img)
```

## Colour models and transparency

The renderer uses RGB internally and converts the result back to the input
model and channel precision. This preserves `Gray`, floating-point RGB, HSV,
Lab and transparent colourants. Alpha values are copied unchanged from the
source image.

Effects with their own palette, including `Duotone`, `Halftone`, a
palette-backed `Dither`, and `VoronoiStained`, produce colour when their input
is grayscale. Use
`output_type` to request another representation explicitly:

```julia
using Colors
perceptual = apply(Oil(), img; output_type = Lab{Float32})
```

## Reusing point clouds

Resolve a seeding strategy once when several frames or effects must share
identical geometry:

```julia
points = sow(Scatter(points = 3_000, seed = 42), img)
facets = apply(LowPoly(points), img)
cells = apply(Voronoi(points), img)
```

## Appearance and framing

Use `fit_cover` for a centred cover crop and `Appearance.DARK` when an effect
should render a twilight variant:

```julia
framed = fit_cover(img, 1920, 1080)
dark = apply(Oil(), framed; appearance = Appearance.DARK)
```

## Sequences

An effect may be selected as a function of time:

```julia
effect(t) = Posterize(levels = 4 + round(Int, 2sin(t)))
frames = render(effect, img, range(0, 2π; length = 48))
```

`render` is lazy, so frames can be encoded without storing the complete
sequence in memory.
