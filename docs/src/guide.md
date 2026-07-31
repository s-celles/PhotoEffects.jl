# Guide

## Choosing an effect

| Effect | Result |
|---|---|
| `LowPoly` | Delaunay triangles filled with sampled colours |
| `Voronoi` | Polygonal cells painted from area averages |
| `Oil` | Edge-preserving Kuwahara painting |
| `Posterize` | Quantized colour bands with optional outlines |
| `Duotone` | Luminance mapped onto a colour ramp |
| `Halftone` | Tone represented by marks on a rotated screen |

```julia
effect = LowPoly(points = 3_000, seed = 42)
result = apply(effect, img)
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
