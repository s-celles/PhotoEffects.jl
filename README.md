# PhotoEffects.jl

Turn a photograph into a stylised image — flat facets, polygonal cells,
painterly impasto — in a light or a twilight variant.

```julia
using FileIO, PhotoEffects

img = load("photo.jpg")
out = apply(Oil(radius = 9, passes = 2), fit_cover(img, 2880, 1864))
save("wallpaper.png", out)

dark = apply(Oil(), fit_cover(img, 2880, 1864);
             appearance = Appearance.DARK)
```

## Why this package

The building blocks already exist in the Julia ecosystem —
`DelaunayTriangulation.jl` for triangulation, `DitherPunk.jl` for dithering,
`ImageFiltering.jl` and `ImageSegmentation.jl` for the rest. **The assembly
does not**: no package in the General registry does artistic image
stylisation. That is the gap this one fills.

## Design

An effect is an **immutable value carrying its parameters**, never an image:

```julia
abstract type AbstractEffect end
struct Oil <: AbstractEffect
    radius::Int
    passes::Int
end
```

`apply(effect, img)` dispatches on the effect type. Everything shared across
the catalogue — the `fit_cover` crop, the `twilight` variant, eventually the
multi-resolution render loop — is written **once**, however many effects
there are.

The dark variant is not a separate effect: it is the same image taken to
twilight, so both versions of a wallpaper share the exact same geometry.

## Effects

| Effect | Family | Principle |
|---|---|---|
| `LowPoly` | tessellation | Delaunay triangulation, flat facets |
| `Voronoi` | tessellation | polygonal cells, mean colour |
| `Oil` | painting | Kuwahara filter |
| `Posterize` | painting | channels snapped to N levels, optional inked edges |
| `Duotone` | minimal | luminance mapped onto a colour ramp |
| `Halftone` | screen | tone as dot area on a tilted lattice |

See [ROADMAP.md](ROADMAP.md) for the effects still to come.

### `Oil` — oil painting (Kuwahara)

For every pixel, the four overlapping quadrants around it are evaluated; the
most homogeneous one wins, and the pixel takes its mean colour.

In the middle of a flat area the quadrants are equivalent and the region
smooths into impasto; on an edge, only the quadrant on the correct side is
homogeneous, so colour never crosses the boundary. A blur would average both
sides — that is the whole difference.

The computation goes through integral images: the cost **does not depend** on
the radius. Selection arithmetic is integral (luminance in thousandths,
variance compared as `n·Σx² − (Σx)²`), so the render depends neither on
summation order nor on dependency versions.

`radius` is in **pixels**: it must scale with the output width, otherwise the
grain changes from one resolution to the next.

| Width | `radius` |
|---|---|
| 1920 | 6 |
| 2880 | 9 |
| 5120 | 16 |

### `LowPoly` and `Voronoi` — the two tessellations

Both start from the same seeding: points drawn **dense along edges** and
sparse over flat areas, so facets are small where the image varies and large
across the sky — that is what makes shapes survive the simplification.

They then part ways on the tiling, each the dual of the other:

- `LowPoly` triangulates the seeds (`DelaunayTriangulation.jl`) and fills each
  triangle with the mean of its centroid and three vertices.
- `Voronoi` attaches every pixel to its nearest seed and paints each cell with
  a genuine area average — gradients survive better.

Sampling without replacement uses the A-Res algorithm of
Efraimidis–Spirakis: one single sweep instead of the quadratic sequential
draw of a naive approach.

`seed` fixes the point draw. Equal seeds give identical renders, including
across Julia versions: the stream comes from `StableRNGs.jl`, since the
`Random` stream is not guaranteed stable between versions — which matters
when the resulting PNGs are version-controlled.

> **Why there are no explicit Voronoi polygons.** Cell membership *is*
> "the nearest seed": a KDTree computes it exactly and covers the whole image
> without the delicate clipping that rasterising polygons at the border would
> require. Explicit geometry (`DelaunayTriangulation.voronoi`,
> `centroidal_smooth`) will become necessary for stained-glass leading and for
> Lloyd relaxation.

### `Posterize` — poster / cel-shading

Each channel is snapped to `levels` values, collapsing gradients into hard
bands the way a screen print reproduces a photograph with a limited number of
inks. The quantisation grid includes both endpoints, so pure black and pure
white survive and the mapping is **idempotent** — re-applying changes
nothing, and bands never drift.

`outline` inks the contours above a given edge strength, which turns the
poster look into cel-shading: bands become fills, edges become linework.

### `Duotone` — gradient map

Every pixel is reduced to its luminance, which then indexes a ramp built from
`stops`. Tonal structure survives, the original hues do not.

With two stops the entire image lies on a segment of RGB space — that is what
makes it read as two inks rather than a tinted photo. More stops bend the
ramp; a saturated third one gives the classic split-tone. Since only
luminance survives, light and dark variants are a matter of picking pale or
deep stops rather than post-processing.

### `Halftone` — offset screen

The image is covered by a tilted lattice; each cell is inked over a fraction
of its area proportional to local darkness. Seen from far enough the eye
integrates coverage back into continuous tone; up close it is offset
printing.

Output holds **two colours only** — a halftone simulates grey through area,
never through intermediate tones.

The lattice is rotated (45° by default) because an unrotated screen aligns
with the pixel grid and beats against it into moiré. Like `Oil`'s radius,
`cell` is in **pixels** and must scale with the output width.

## Cropping

`fit_cover` enlarges until the target format is covered, then trims the
overflow at the centre. Downscaling happens in two stages: antialiased 2:1
decimation via `restrict` while a factor of two is still available, then
Lanczos for the fractional step. `imresize` alone **interpolates without
averaging** and makes foliage crawl on a photo reduced by a factor of two or
more.

## Tests

```sh
julia --project=test test/runtests.jl
```

Tests target the **properties** that define each effect rather than pixel
values: for `Oil`, "a hard step stays hard, with no intermediate value at
all"; for `fit_cover`, "a 1px checkerboard reduced gives flat grey, not a
solid field nor moiré".

## Reproducibility

Renders are meant to be version-controlled, so the same call must produce the
same image.

`Oil` is deterministic by construction: it involves no random draw at all, and
its quadrant selection is entirely integral, so the result depends neither on
summation order nor on dependency versions.

`LowPoly` and `Voronoi` draw their seeds, and take a `seed` parameter to pin
that draw. Their stream comes from `StableRNGs.jl` rather than `Random`, whose
output is not guaranteed stable across Julia versions.

Note that the encoded PNG can still differ between machines even when the
pixels are identical, since compression depends on the imaging stack. Pin your
toolchain if byte-level reproducibility matters.

## License

MIT — see [LICENSE](LICENSE).
