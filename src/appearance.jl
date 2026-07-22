"""
Target appearance of a render: light background or dark background.

Dark is not a separate effect — it is the same image taken to twilight by
[`twilight`](@ref), so that both variants of a wallpaper share the exact same
geometry.
"""
module Appearance
@enum T begin
    LIGHT
    DARK
end
end

"""
Darken `img` for a dark-mode wallpaper (twilight mood).

Works in HSV: hue is preserved, saturation is nudged up by `saturation`, and
value is remapped onto the band `[shadow, 1] * value` after a `gamma` bend.
Flat areas stay flat — a tessellation effect therefore keeps its cells
perfectly uniform.

The band matters more than the ceiling. Scaling value straight down towards
zero crushes the shadows together and the picture reads as underexposed rather
than as dusk; keeping a `shadow` above black holds the darks apart, so the
image stays legible at a fraction of its original brightness.

The defaults are shared by every effect, so that their dark variants stay
consistent with one another.
"""
function twilight(img::AbstractMatrix{<:Colorant};
                  value::Real = 0.30,
                  shadow::Real = 0.10,
                  gamma::Real = 1.2,
                  saturation::Real = 1.25)
    value > 0 || throw(ArgumentError("value must be > 0, got $value"))
    gamma > 0 || throw(ArgumentError("gamma must be > 0, got $gamma"))
    0 <= shadow < 1 ||
        throw(ArgumentError("shadow must be in [0, 1), got $shadow"))
    lo = shadow * value
    hi = value
    out = similar(img, RGB{N0f8})
    @inbounds for i in eachindex(img)
        c = HSV(RGB(img[i]))
        v = clamp(lo + (hi - lo) * (c.v^gamma), 0, 1)
        s = clamp(c.s * saturation, 0, 1)
        out[i] = RGB{N0f8}(clamp01(RGB(HSV(c.h, s, v))))
    end
    return out
end
