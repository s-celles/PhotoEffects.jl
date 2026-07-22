# Roadmap — effect catalogue

Effects are grouped by family. Each one turns a photograph into a stylised
image, in a light and a twilight variant.

Status: ✅ done · 🟡 next up · ⚪ planned · 🔬 exploratory

**6 of 24 done**, across four of the seven families.

---

## 1. Tessellation

Cuts the image into flat cells with crisp edges. Preserves the main shapes
well.

### ✅ `LowPoly` — Delaunay triangulation
Flat triangular facets, seeds dense along edges. Faceted-crystal look.

### ✅ `Voronoi` — Voronoi diagram
Polygonal "pebble / stained glass" cells, the dual of Delaunay. Rounder and
more organic than low-poly.

### 🟡 `VoronoiStained` — Voronoi with leading
Voronoi plus thin **dark joints** between cells. Reads as stained glass or
Roman mosaic — more graphic, more legible. The cell polygons come from
`DelaunayTriangulation.voronoi`; what remains is stroking them, and clipping
them to the image rectangle.

### 🟡 `VoronoiLloyd` — centroidal Voronoi
A few Lloyd iterations give cells of **even size**, a calmer and more regular
"scales" look. `DelaunayTriangulation.centroidal_smooth` provides the
primitive.

### ⚪ `HexMosaic` — hexagonal mosaic
Regular hexagon grid, each cell in its mean colour. Honeycomb aesthetic, very
clean and retro-tech. Easy: fixed lattice plus per-cell mean.

### ⚪ `PixelMosaic` — square mosaic
Square blocks in mean colour. Large blocks give retro pixel art, small ones a
pointillist impression. Option: light joints between tiles for a tiled look.

### ⚪ `Cubist` — random convex polygons
Larger, more angular irregular polygons with slightly shifted colours.
Cubist / abstract stained glass. `ImageSegmentation.jl` can seed the regions.

---

## 2. Painting

Reproduces painterly media. Keeps the scene while dreaming it.

### ✅ `Oil` — Kuwahara filter
Flattens into smoothed, edge-preserving patches: thick brushwork, impasto.

### ✅ `Posterize` — posterisation / cel-shading
Channels snapped to N levels, with optional inked contours. Screen-print,
poster, comic-book look.

### 🟡 `Watercolour` — watercolour
Bleeding edges, soft washes, granulation, lighter halos. Soft segmentation
plus edge noise and a paper texture overlay. Delicate and pastel — ideal as a
light variant. Moderate to hard.

### ⚪ `Brushes` — impressionist strokes
Thousands of strokes oriented by the local gradient (stroke-based rendering).
Van Gogh / Monet: matter and movement. Hard.

### ⚪ `Pointillism` — pointillism
A swarm of coloured dots of varying size, density following detail. Seurat.

---

## 3. Screen / halftone / linear

Reinterprets the image as dots, lines or characters. Very graphic.

### ✅ `Halftone` — halftone screen
Dot area encodes tone on a tilted lattice. Offset print / pop art.
A CMYK colour version is still possible.

### 🟡 `Dither` — ordered / Floyd–Steinberg dithering
Reduced palette plus error diffusion or a Bayer matrix. Retro console
(2–4 tone palette) or old press. **`DitherPunk.jl` already implements this** —
this entry is about wiring it in behind the `AbstractEffect` interface, not
reimplementing it.

### ⚪ `Contour` — iso-luminance contours
Topographic-map lines. Spare and cartographic, very elegant in monochrome or
duotone.

### ⚪ `Hatching` — hatching / engraving
Crossed strokes whose density encodes shadow. Engraving or pen drawing.

### 🔬 `Ascii` — ASCII art
Rendered in monospace characters through a density ramp. Easy in principle;
the care goes into font, resolution and aspect ratio.

---

## 4. Minimal / vector

Reduces the image to essentials: silhouettes, flats, lines.

### ✅ `Duotone` — duotone / tritone
Luminance mapped onto a 2–3 colour ramp. Spotify / minimalist-poster look.

### ⚪ `Blobs` — soft colour blobs
Dominant palette extracted, then a gradient background with large blurred
blobs. Abstract and calm; keeps the mood, not the shapes.

### ⚪ `LineArt` — edge detection only
Contours alone on a plain background. `ImageEdgeDetection.jl` provides Canny.

### 🔬 `TspArt` — single continuous line
One unbroken stroke (a travelling-salesman path over stippled points)
reconstitutes the image. Hypnotic. Hard.

---

## 5. Procedural / generative

Treats the photo as a data field. More experimental.

### 🔬 `FlowField` — flow field
Particles following the image gradient, leaving coloured trails. Ink-in-water
look. `CoherentNoise.jl` covers the noise, though it is dormant and has no
built-in looping.

### 🔬 `ReactionDiffusion` — tinted Turing patterns
Gray–Scott patterns coloured by the photo. Coral or skin texture. No
ready-made Julia package aimed at imagery — a 2D Gray–Scott is about thirty
lines, and periodic boundaries give a tileable pattern for free.

### 🔬 `Glitch` — glitch / datamosh
RGB channel offsets, slices, chromatic aberration, pixel sorting. Vaporwave.
Nothing exists in Julia for pixel sorting; it is a sort over thresholded runs
per row, and Julia suits it well.

---

## 6. Composable post-processing

To layer over any effect above:

- **Grain / paper texture** — silver-halide or watercolour-paper matter.
- **Vignette / bloom** — focuses the eye, softens the mood.
- **Tilt-shift** — progressive blur top and bottom, miniature effect.
- **Border / mat** — framed-print look.

These argue for a `Pipeline` or `Chain` effect combining several
`AbstractEffect`s, rather than a flag on each one.

---

## 7. Animation

Two independent axes: **what** moves, and **how** it is delivered.

### Axis A — the style moves, the photo is still
Generators are procedural and deterministic, so their parameters can depend
on time `t`:

- **Drifting seeds** (Voronoi / low-poly): each seed oscillates around its
  position, so cells breathe and shimmer like a faceted water surface. Nearly
  free given the current code.
- **Animated Lloyd relaxation**: random seeds converging to centroidal, cells
  reorganising then settling — a good intro.
- **Pulsing density**, or **morphing between effects**.

### Axis B — the content moves
- **Cinemagraph**: isolate a region (water, sky) and loop a micro-movement
  while the rest stays frozen.
- **2.5D parallax**: estimate a depth map, then a slight camera move.

### Axis C — the light moves
- **Day–night cycle**: interpolate between the light and twilight variants
  according to real time.

### Delivery

`VideoIO.jl` (actively maintained) encodes H.264 from a frame stack, with
control over framerate and CRF. **Avoid `Javis.jl`**: 843 stars but pinned to
Luxor 3.x with no human commit since 2022 — it will break dependency
resolution against current Luxor.

**Seamless looping** is a property of frame generation, not of the encoder:
drive motion with periodic functions so that frame `N` equals frame `0`, and
force a keyframe interval dividing `N` so players do not stutter at the loop.

---

## Conventions for a new effect

- A subtype of `AbstractEffect` holding **only parameters**, never an image,
  plus a `_render(::MyEffect, ::Matrix{RGB{N0f8}})` method.
- Validate parameters in the constructor, throwing `ArgumentError`.
- A finite set of choices is a **module-scoped enum** (see `HalftoneShape`),
  never a `Symbol` or a string.
- Randomness goes through `StableRNGs`, seeded by a `seed` field — renders
  are meant to be version-controlled.
- A parameter expressed in **pixels** (`radius`, `cell`) has to scale with the
  output width; one expressed as a **count** (`points`) is already relative.
  Say which in the docstring.
- Tests target the **properties** that define the effect, not pixel values:
  total coverage, flat cells, a hard step staying hard, idempotence,
  monotonicity in the parameter.
- Prefer a maintained package over reimplementing, and check the General
  registry first — several entries above are wiring jobs, not algorithms.
