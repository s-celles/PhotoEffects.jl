"""
Test image with a graded range of edge strengths: a nearly flat field, one
narrow modulated band, and a tiny ultra-contrast spot standing in for the
specular highlight every photograph has.

Three things make it discriminating:

- the **grading** tells a robust normalisation from a fragile one — a binary
  edge saturates under any scheme and hides the difference;
- the modulation stays well above the pixel frequency, or the blur in
  `PhotoEffects._edge_map` would erase it and leave nothing to measure;
- the band covers only [`BAND_AREA`](@ref) of the width, so the share of seeds
  landing in it starts near that figure and has room to climb. Over half the
  image it would saturate at once and any trend would be lost in the ceiling.
"""
function _graded_image()
    img = Matrix{RGB{N0f8}}(undef, 100, 100)
    for y in 1:100, x in 1:100
        v = x in BAND ? 0.5 + 0.1 * sin(2π * x / 10) * sin(2π * y / 10) :
            0.45 + 0.001 * x
        img[y, x] = RGB{N0f8}(clamp(v, 0, 1))
    end
    img[20:21, 20:21] .= RGB{N0f8}(1, 1, 1)   # the outlier
    return img
end

"Columns carrying the texture in [`_graded_image`](@ref)."
const BAND = 60:75

"Share of the image area covered by [`BAND`](@ref) — the uniform-seeding baseline."
const BAND_AREA = 0.16
