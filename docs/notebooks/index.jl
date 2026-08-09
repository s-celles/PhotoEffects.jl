#%% md id=title tags=title,home
@md"""
# PhotoEffects.jl

Turn a photograph into a stylised image — flat facets, polygonal cells,
painterly impasto, halftone screens — in a light or twilight variant.

Move the controls below: every image on this page is produced by the package
itself, live.
"""

#%% code id=setup tags=hidecode
using PhotoEffects
using ImageCore
using ImageShow      # without it, large images render as reduced swatches
using MosaicViews
using TestImages

#%% md id=source_md
@md"""
## The source image

`lighthouse` from **TestImages.jl** — the canonical JuliaImages demo
photograph, and good material here for a specific reason: it holds a smooth
sky gradient, a hard-edged silhouette, and fine grass texture all at once.
Those three are exactly what separate one effect from another. An image with
only one of them makes every effect look alike.

Swap `SOURCE` for your own photograph — `load("my-photo.jpg")` — to see the
effects on your own material.
"""

#%% code id=source
SOURCE = RGB{N0f8}.(testimage("lighthouse"))

#%% md id=gallery_md
@md"""
## The catalogue at a glance

Eighteen effects, four families. Each is shown at representative parameters.
"""

#%% code id=gallery tags=hidecode
let small = fit_cover(SOURCE, 320, 180)
    shots = [apply(LowPoly(points = 700), small),
        apply(Voronoi(points = 500), small),
        apply(VoronoiStained(points = 500, joint = 1), small),
        apply(VoronoiLloyd(points = 500, iterations = 2), small),
        apply(Cubist(points = 90, shift = 0.18), small),
        apply(HexMosaic(cell = 8), small),
        apply(PixelMosaic(block = 10, joint = 1), small),
        apply(Oil(radius = 3), small),
        apply(Posterize(levels = 9), small),
        apply(Watercolour(radius = 3), small),
        apply(Brushes(strokes = 700, length = 7, width = 2), small),
        apply(Pointillism(points = 500, max_radius = 3), small),
        apply(Duotone(), small),
        apply(LineArt(), small),
        apply(Halftone(cell = 6), small),
        apply(Contour(levels = 7), small),
        apply(Hatching(spacing = 6), small),
        apply(Dither(method = DitherMethod.BAYER), small)]
    # rowmajor: mosaicview fills columns first by default, which would put the
    # tiles in a different order from the one the caption reads out below.
    mosaicview(shots...; nrow = 3, rowmajor = true, npad = 6,
        fillvalue = RGB{N0f8}(1, 1, 1))
end

#%% md id=labels
@md"""
Reading order: **LowPoly**, **Voronoi** · **VoronoiStained**,
**VoronoiLloyd**, **Cubist** · **HexMosaic**, **PixelMosaic** · **Oil**, **Posterize** ·
**Watercolour**, **Brushes**, **Pointillism**, **Duotone**, **LineArt** · **Halftone**, **Contour**,
**Hatching**, **Dither**.

## Tessellation — seeds, then a tiling

`LowPoly` and `Voronoi` share their seeding: points drawn dense along edges and
sparse over flat areas, so facets stay small where the image varies. They then
part ways on the tiling, each the dual of the other.

Raise `points` and the facets shrink. The parameter that decides the
*character*, though, is `background`: it sets the share of seeds drawn
uniformly rather than from the edge map. High, and the mesh stays even and
merely tightens on the subject; low, and the seeds crowd onto the silhouettes
and leave the sky in a few large plates.

`detail` only sharpens the contrast within the edge term, and it does not
climb without end — the share of seeds landing on a region peaks around 2 and
falls away after, as the handful of saturated pixels take the edge term over.
Reach for `background` first.
"""

#%% code id=tess_controls
@bind points Slider(120:80:2000; default = 840)
@bind detail Slider(0.0:0.25:4.0; default = 1.5)
@bind background Slider(0.0:0.5:10.0; default = 5.0)
@bind dual Select(["LowPoly", "Voronoi"])

#%% code id=tess
let img = fit_cover(SOURCE, 640, 360)
    e = dual == "LowPoly" ? LowPoly(; points, detail, background) :
        Voronoi(; points, detail, background)
    apply(e, img)
end

#%% md id=cubist_md
@md"""
## Cubist planes

A sparse convex tessellation simplifies the photograph into broad angular
planes. `shift` then separates adjacent cell colours without changing their
geometry; both the planes and their colour displacement are reproducible.
"""

#%% code id=cubist_controls
@bind cubist_points Slider(30:15:240; default = 90)
@bind cubist_shift Slider(0.0:0.02:0.4; default = 0.18)

#%% code id=cubist
apply(Cubist(points = cubist_points, shift = cubist_shift, seed = 42),
    fit_cover(SOURCE, 640, 360))

#%% md id=mosaic_md
@md"""
## Regular mosaics — honeycomb or square tiles

Both effects use the exact mean colour beneath every cell. Hexagons come from
nearest membership on a triangular lattice; square tiles can expose a light
joint for a ceramic look.
"""

#%% code id=mosaic_controls
@bind mosaic_cell Slider(4:2:24; default = 10)
@bind mosaic_kind Select(["Hexagonal", "Square"])
@bind mosaic_joint Toggle(; label = "Tile joints")

#%% code id=mosaic
let effect = mosaic_kind == "Hexagonal" ? HexMosaic(cell = mosaic_cell) :
             PixelMosaic(block = mosaic_cell, joint = mosaic_joint ? 1 : 0)
    apply(effect, fit_cover(SOURCE, 640, 360))
end

#%% md id=composition_md
@md"""
## Composition and colour models

`Pipeline` applies stages from left to right. Colour-space conversion happens
once around the complete pipeline. Opaque and transparent inputs keep their
colour model and channel precision; alpha is copied unchanged.
"""

#%% code id=composition
let img = fit_cover(SOURCE, 640, 360)
    apply(Pipeline(Oil(radius = 2), Posterize(levels = 7), Duotone()), img)
end

#%% md id=oil_md
@md"""
## Painting — patches that follow the shapes

`Oil` keeps, for each pixel, the most homogeneous of the four quadrants around
it. Flat areas smooth into impasto while edges stay put, because only the
quadrant on the correct side of an edge is ever homogeneous.

Watch the hills: their silhouettes survive at radii that erase the water
texture entirely. A blur would have taken both.
"""

#%% code id=oil_controls
@bind radius Slider(0:2:16; default = 6)
@bind passes Slider(1:1:4; default = 1)

#%% code id=oil
apply(Oil(; radius, passes), fit_cover(SOURCE, 640, 360))

#%% md id=poster_md
@md"""
## Posterize — bands, and optional linework

Channels are snapped to `levels` values. The grid includes both endpoints, so
with `smoothing = 0` the mapping is idempotent: re-applying never lets the
bands drift. By default a median filter flattens the grain first, otherwise
photographic noise lands on either side of a threshold at random and speckles
every band with confetti.

Take `levels` down to 5 or less and the sky turns grey and mauve. That is not
a bug to be smoothed away: each channel crosses its own thresholds at its own
place, so the further apart the levels sit, the further the snapped colour
drifts from the one it stands for. Nine is about where the drift stops
showing.

Push `outline` above zero and the poster becomes cel-shading — bands turn into
fills, edges into linework.
"""

#%% code id=poster_controls
@bind levels Slider(2:1:12; default = 9)
@bind outline Slider(0.0:0.05:0.6; default = 0.0)

#%% code id=poster
apply(Posterize(; levels, outline), fit_cover(SOURCE, 640, 360))

#%% md id=watercolour_md
@md"""
## Watercolour — wet edges and paper grain

`bleeding` mixes pigment across a neighbourhood set by `radius`, while
`granulation` breaks perfectly flat digital colour into a reproducible wash.
The `paper` control leaves more of the white support visible.
"""

#%% code id=watercolour_controls
@bind bleeding Slider(0.0:0.1:1.0; default = 0.5)
@bind granulation Slider(0.0:0.02:0.2; default = 0.08)
@bind paper Slider(0.0:0.05:0.4; default = 0.12)

#%% code id=watercolour
apply(Watercolour(; radius = 4, bleeding, granulation, paper, seed = 42),
    fit_cover(SOURCE, 640, 360))

#%% md id=brushes_md
@md"""
## Brushes — gradient-oriented marks

Stroke centres concentrate on detail and each mark borrows the local source
colour. The luminance gradient gives structure its direction, while seeded
orientations keep flat fields alive.
"""

#%% code id=brushes_controls
@bind brush_count Slider(300:300:3000; default = 1800)
@bind brush_length Slider(3:2:17; default = 9)

#%% code id=brushes
apply(
    Brushes(strokes = brush_count, length = brush_length,
        width = 2, seed = 42),
    fit_cover(SOURCE, 640, 360))

#%% md id=pointillism_md
@md"""
## Pointillism — colour through discrete marks

Dots borrow their colour from the source. Their centres concentrate around
detail while a uniform component keeps quiet regions represented; varying
radii prevent the result from reading as a rigid screen.
"""

#%% code id=pointillism_controls
@bind dot_count Slider(200:200:2400; default = 1200)
@bind dot_radius Slider(1:1:6; default = 4)

#%% code id=pointillism
apply(
    Pointillism(points = dot_count, min_radius = 1,
        max_radius = dot_radius, seed = 42),
    fit_cover(SOURCE, 640, 360))

#%% md id=halftone_md
@md"""
## Halftone — tone as area, not as tone

Each cell of a tilted lattice is inked over a fraction of its area set by the
mean darkness **over that cell** — a screen integrates the area it covers, and
reading a single pixel instead would let the grain in the rocks size the dots
and turn the whole foreground into static. The output holds **two colours
only**: a halftone simulates grey through coverage, never through intermediate
tones.

`gamma` bends tone into area. At `1.0` the area is strictly proportional to
darkness, and a photograph whose tones all sit near the middle screens to
roughly half coverage everywhere — a flat grey texture carrying almost no
image. Raising it opens the highlights back up, which is the same correction a
press makes for dot gain.

Set `angle` to zero and the moiré appears — the screen aligns with the pixel
grid and beats against it. That is why 45° is the traditional value.
"""

#%% code id=halftone_controls
@bind cell Slider(3:1:16; default = 8)
@bind angle Slider(0.0:0.13:1.57; default = 0.78)
@bind gamma Slider(0.6:0.2:3.0; default = 1.8)
@bind square Toggle(; label = "Square marks")

#%% code id=halftone
let shape = square ? HalftoneShape.SQUARE : HalftoneShape.DOT
    apply(Halftone(; cell, angle, gamma, shape), fit_cover(SOURCE, 640, 360))
end

#%% md id=contour_md
@md"""
## Contour — luminance as elevation

Evenly spaced luminance bands become topographic boundaries. More levels
retain subtle modelling; fewer levels reduce the scene to a sparse map.
"""

#%% code id=contour_controls
@bind contour_levels Slider(2:1:16; default = 8)
@bind contour_width Slider(1:1:3; default = 1)

#%% code id=contour
apply(Contour(levels = contour_levels, width = contour_width),
    fit_cover(SOURCE, 640, 360))

#%% md id=hatching_md
@md"""
## Hatching — shadow through crossed ink

The first line family establishes a drawing; deeper tones activate additional
angles. Shadows therefore gain physical ink density instead of merely becoming
darker pixels.
"""

#%% code id=hatching_controls
@bind hatch_spacing Slider(3:1:12; default = 7)
@bind hatch_layers Slider(1:1:3; default = 3)

#%% code id=hatching
apply(Hatching(spacing = hatch_spacing, layers = hatch_layers),
    fit_cover(SOURCE, 640, 360))

#%% md id=dither_md
@md"""
## Dither — reduced palettes

Floyd–Steinberg diffuses quantisation error into following pixels; Bayer uses
a fixed threshold matrix and produces a more visibly ordered retro texture.
"""

#%% code id=dither_control
@bind ordered Toggle(; label = "Ordered Bayer matrix")

#%% code id=dither
let method = ordered ? DitherMethod.BAYER : DitherMethod.FLOYD_STEINBERG
    apply(Dither(; method, levels = 4), fit_cover(SOURCE, 640, 360))
end

#%% md id=duotone_md
@md"""
## Duotone — luminance mapped onto two inks

Every pixel is reduced to its luminance, which then indexes a ramp. Tonal
structure survives; the original hues do not. With two stops the whole image
lies on a segment of RGB space.

Lying on a segment is not by itself enough to read as two inks. The defaults
run from a deep indigo to a pale sand — near-opposite ends of the lightness
scale — so the midpoint of the ramp, where most of a photograph sits, comes
out very close to neutral grey and the result reads as a tinted photo. Drag
the two stops closer in lightness and further apart in hue, and the second ink
starts asserting itself across the midtones instead of only at the ends.
"""

#%% code id=duotone_controls
@bind shadow ColorPicker("#0f1740")
@bind highlight ColorPicker("#fae8c2")

#%% code id=duotone
let stops = [parse(RGB, shadow), parse(RGB, highlight)]
    apply(Duotone(stops), fit_cover(SOURCE, 640, 360))
end

#%% md id=lineart_md
@md"""
## Line art — structure without tone

The robust normalized edge scale keeps the threshold meaningful across
photographs. Only gradients survive; ink and paper replace all source colour.
"""

#%% code id=lineart_controls
@bind line_threshold Slider(0.05:0.05:0.9; default = 0.2)
@bind line_width Slider(1:1:3; default = 1)

#%% code id=lineart
apply(LineArt(threshold = line_threshold, width = line_width),
    fit_cover(SOURCE, 640, 360))

#%% md id=dark_md
@md"""
## Light and twilight

The dark variant is not a separate effect: it is the same image taken to
twilight. Both share the exact same geometry, which is what lets a wallpaper
switch with the system appearance without the layout shifting underneath.

Twilight remaps brightness onto a *band* rather than scaling it towards zero.
Scaling collapses the shadows into one another and the picture reads as
underexposed; holding the darkest tone a little above black keeps them apart,
so the image is still legible at a fraction of its original brightness.
"""

#%% code id=dark
let img = fit_cover(SOURCE, 400, 225)
    e = LowPoly(points = 900)
    mosaicview(apply(e, img; appearance = Appearance.LIGHT),
        apply(e, img; appearance = Appearance.DARK);
        nrow = 1, rowmajor = true, npad = 6,
        fillvalue = RGB{N0f8}(1, 1, 1))
end

#%% md id=next
@md"""
## Next

The [roadmap](https://github.com/s-celles/PhotoEffects.jl/blob/main/ROADMAP.md)
lists the twelve effects still to come, and the conventions a new one must
follow.
"""

# ╔═╡ Slate.config · per-notebook settings (Settings panel)
#   docid = dadcd6ef-dd35-468b-bf09-a0c2d9430e92
# ╚═╡
