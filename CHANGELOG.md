# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `Seeding` hierarchy (`Scatter`, `Given`, `sow`) to extract point generation into a first-class citizen.
- `render` and `frame` to lazily evaluate sequences of frames (`t -> AbstractEffect`) or generate isolated frames.
- `AbstractEffect` hierarchy and the `apply` entry point, dispatching on the
  effect type.
- `Oil` effect — oil painting through the Kuwahara filter. Integral images
  (cost independent of the radius) and integer selection arithmetic.
- `LowPoly` and `Voronoi` effects — the two dual tessellations. Triangulation
  by `DelaunayTriangulation.jl`; Voronoi cells rasterised by nearest-seed
  membership (`NearestNeighbors.jl`).
- Seeding shared by the tessellations: Sobel edge map, A-Res draw without
  replacement concentrated along edges, and a border frame so the convex hull
  reaches the image corners.
- `fit_cover` — centred cover crop, with antialiased decimation via `restrict`
  ahead of the fractional Lanczos step.
- `twilight` and the `Appearance` enum — twilight variant sharing the geometry
  of the light one.
- `Posterize` effect — channels snapped to N levels, with optional inked
  contours for a cel-shaded look. The quantisation grid includes both
  endpoints, so the mapping is idempotent and pure black and white survive.
- `Duotone` effect — luminance mapped onto a ramp of two or more stops.
- `Halftone` effect — tone rendered as dot area on a tilted lattice, with a
  `HalftoneShape` enum for dot or square marks.
- Property-oriented `TestItemRunner` tests, and Aqua quality checks.
- `ROADMAP.md` — the full effect catalogue and the conventions a new effect
  must follow.

### Changed

- `Voronoi` and `LowPoly` now carry a `seeding::Seeding` field instead of scattering parameters. The old keyword constructors are preserved for backward compatibility (they implicitly build a `Scatter` strategy), causing no breaking change.
- The edge map now scales gradient magnitudes by their 95th percentile,
  clamping above it, instead of dividing by the maximum. A single extreme
  gradient — a specular highlight, a blown sky — used to set the scale for the
  whole image and push everything that actually draws the subject towards
  zero. Since `edges^detail` then shrank the entire map, the uniform
  background of the draw took over and raising `detail` *spread* the seeds
  instead of concentrating them. Clamping pins strong edges at 1, so the
  exponent can only push flat areas down.

  This changes what `LowPoly` and `Voronoi` render at a given `detail`:
  the same value now concentrates seeds appreciably more. Renders meant to be
  reproduced need their `detail` re-picked, not carried over.

  `detail` stays monotone only over its usable range — roughly up to 4.
  Beyond that the absolute `background` floor reasserts itself and the trend
  reverses; making the floor relative to the mean edge weight would lift the
  ceiling, at the cost of redefining `background`.
