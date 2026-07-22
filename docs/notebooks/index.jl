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

Six effects, four families. Each is shown at its default parameters.
"""

#%% code id=gallery tags=hidecode
let small = fit_cover(SOURCE, 320, 180)
    shots = [apply(LowPoly(points = 700), small),
             apply(Voronoi(points = 500), small),
             apply(Oil(radius = 3), small),
             apply(Posterize(levels = 9), small),
             apply(Duotone(), small),
             apply(Halftone(cell = 6), small)]
    # rowmajor: mosaicview fills columns first by default, which would put the
    # tiles in a different order from the one the caption reads out below.
    mosaicview(shots...; nrow = 3, rowmajor = true, npad = 6,
               fillvalue = RGB{N0f8}(1, 1, 1))
end

#%% md id=labels
@md"""
Reading order: **LowPoly**, **Voronoi** · **Oil**, **Posterize** ·
**Duotone**, **Halftone**.

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
lists the eighteen effects still to come, and the conventions a new one must
follow.
"""

# ╔═╡ Slate.config · per-notebook settings (Settings panel)
#   docid = dadcd6ef-dd35-468b-bf09-a0c2d9430e92
# ╚═╡
