"""
Scale `img` to cover `width`×`height`, then crop the overflow at the centre.

The image is enlarged until it fully covers the target format (scale factor =
max of both ratios) and the excess is trimmed symmetrically. No empty band
ever appears, at the cost of losing some of the longer dimension.

Downscaling happens in two stages. `imresize` **interpolates** without
averaging: applied directly to a photo reduced by a factor of two or more, it
samples every other pixel and makes foliage crawl. So we first decimate with
`restrict` — an antialiased 2:1 reduction — while a factor of two is still
available, then let Lanczos handle the remaining fractional step.

Everything runs in floating point, with a final clamp to `[0, 1]`: the
Lanczos kernel rings past that range, which would make the conversion to
`N0f8` throw.
"""
function fit_cover(img::AbstractMatrix{<:Colorant},
                   width::Integer,
                   height::Integer)
    width > 0 || throw(ArgumentError("width must be > 0, got $width"))
    height > 0 || throw(ArgumentError("height must be > 0, got $height"))

    sh, sw = size(img)
    scale = max(width / sw, height / sh)
    nw = max(width, round(Int, sw * scale))
    nh = max(height, round(Int, sh * scale))

    resized = _resample(RGB{Float64}.(img), nh, nw)

    top = (nh - height) ÷ 2
    left = (nw - width) ÷ 2
    window = @view resized[(top + 1):(top + height), (left + 1):(left + width)]

    out = similar(window, RGB{N0f8})
    @inbounds for i in eachindex(window)
        out[i] = RGB{N0f8}(clamp01(window[i]))
    end
    return out
end

"""
Resample to `nh`×`nw`, decimating by powers of two first.

`restrict` halves a dimension while averaging (a `[1, 2, 1]/4` kernel), which
removes the high frequencies before subsampling. It is applied while the
target is at most half the source along that axis, each axis handled
independently — a cover crop does not shrink both dimensions by the same
factor.
"""
function _resample(img::AbstractMatrix{<:Colorant}, nh::Int, nw::Int)
    out = img
    while size(out, 1) >= 2nh && size(out, 1) > 2
        out = restrict(out, 1)
    end
    while size(out, 2) >= 2nw && size(out, 2) > 2
        out = restrict(out, 2)
    end
    size(out) == (nh, nw) && return out
    return imresize(out, (nh, nw); method = Lanczos4OpenCV())
end
