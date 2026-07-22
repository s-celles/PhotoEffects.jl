"""
Quantile of the gradient magnitudes taken as the top of the edge scale.

At 0.95 the strongest 5 % of the pixels saturate — enough to be robust to a
handful of extreme gradients, few enough that a genuinely detailed region
keeps its internal contrast.
"""
const EDGE_QUANTILE = 0.95

"""
Edge map of `img`, normalised to `[0, 1]`.

Sobel gradient magnitude over luminance, after a light blur that keeps sensor
noise from being mistaken for detail. The image border is zeroed out: the
kernel overhangs there and would produce an artificial rim that attracts
every seed.

The scale is the `EDGE_QUANTILE` quantile of the magnitudes, not their
maximum, and everything above it is clamped to 1. Dividing by the maximum
would hand the scale to a single pixel — one specular highlight, and the
gradients that actually draw the subject collapse towards zero. The whole map
would then sit far below 1, where `edges^detail` shrinks *everything* and the
uniform background of [`_sample_points`](@ref) takes over: past a certain
point, raising `detail` would spread the seeds instead of concentrating them.
Clamping pins the strong edges at 1 so the exponent can only ever push the
flat areas down, which is what makes `detail` monotone.

Returns all zeros for a perfectly uniform image — a degenerate case
[`_sample_points`](@ref) has to tolerate.
"""
function _edge_map(img::AbstractMatrix{<:Colorant})
    gray = Float64.(Gray.(img))
    smooth = imfilter(gray, Kernel.gaussian(1))
    gy, gx = imgradients(smooth, KernelFactors.sobel)
    mag = sqrt.(gx .^ 2 .+ gy .^ 2)

    mag[1, :] .= 0
    mag[end, :] .= 0
    mag[:, 1] .= 0
    mag[:, end] .= 0

    # A thin subject on a wide flat field pushes the quantile itself to zero;
    # the maximum is then the only scale left that keeps the edge visible.
    scale = quantile(vec(mag), EDGE_QUANTILE)
    scale > 0 || (scale = maximum(mag))
    scale > 0 || return mag

    return clamp.(mag ./ scale, 0, 1)
end

"""
Draw `n` distinct positions, dense along the edges of `edges`.

A pixel's weight is `edges^detail + background * mean(edges^detail)`: `detail`
widens the gap between detailed regions and flat ones, while the uniform floor
makes sure sky and water still receive seeds — without it, large smooth areas
would stay empty and the tessellation would span them in one piece.

The floor is **relative** to the mean edge weight, which is what makes
`background` a share rather than a magnitude: the uniform term carries
`background / (1 + background)` of the total sampling weight whatever the edge
map looks like. The default of 5 puts that share at 83 %, which is where a
tessellation reads as an even mesh that tightens on the subject rather than as
fine debris around empty plates. An absolute floor cannot do this: its weight
relative to `edges^detail` depends on where that term happens to land, so the
same number means a different split for a different edge operator, a different
image, or a different `detail`. That is what made the parameter untransferable.

!!! warning "`detail` peaks, it does not climb"
    The relative floor fixes the split, not the exponent. Raising `detail`
    redistributes weight *within* the edge term towards the pixels sitting at
    the top of the map — and those are not necessarily the subject. On a
    photograph the share of seeds landing on a given region climbs to roughly
    `detail = 2` and falls away after, as the few saturated pixels take the
    edge term over. Treat 2 as the ceiling of the useful range rather than a
    midpoint, and reach for `background` when what is wanted is a different
    balance between even coverage and concentration.

Sampling without replacement uses the A-Res algorithm of
Efraimidis–Spirakis: a key `log(u) / w` is drawn per pixel and the `n`
largest keys win. One single sweep, against the quadratic sequential draw of
a naive approach.

Returns `(x, y)` pairs — column first, matching the geometric conventions of
`DelaunayTriangulation`, unlike the `(row, column)` indexing of images.
"""
function _sample_points(edges::AbstractMatrix{<:Real},
                        n::Integer,
                        rng::AbstractRNG,
                        detail::Real;
                        background::Real = 5.0)
    h, w = size(edges)
    n <= h * w ||
        throw(ArgumentError("n=$n exceeds the $(h * w) available pixels"))
    background >= 0 ||
        throw(ArgumentError("background must be >= 0, got $background"))

    weights = Vector{Float64}(undef, h * w)
    @inbounds for i in eachindex(weights)
        weights[i] = edges[i]^detail
    end

    # A perfectly uniform image has no edge weight at all; the floor is then
    # the only term left, and any positive constant gives the same uniform draw.
    uniform = background * mean(weights)
    uniform > 0 || (uniform = 1.0)

    keys = Vector{Float64}(undef, h * w)
    @inbounds for i in eachindex(keys)
        keys[i] = log(rand(rng)) / (weights[i] + uniform)
    end

    idx = partialsortperm(keys, 1:n; rev = true)
    # Column-major storage: linear index i is (column - 1) * h + row.
    return [(Float64(cld(i, h)), Float64(mod1(i, h))) for i in idx]
end

"""
Points spread evenly around the border of an `h`×`w` image.

A Delaunay triangulation only covers the convex hull of its points. Without
this frame, the area between the seed cloud and the image border would stay
unpainted.
"""
function _border_points(h::Integer, w::Integer; steps::Integer = 16)
    xs = range(1.0, Float64(w); length = steps)
    ys = range(1.0, Float64(h); length = steps)
    pts = Tuple{Float64, Float64}[]
    for x in xs
        push!(pts, (x, 1.0), (x, Float64(h)))
    end
    for y in ys
        push!(pts, (1.0, y), (Float64(w), y))
    end
    return unique(pts)
end
