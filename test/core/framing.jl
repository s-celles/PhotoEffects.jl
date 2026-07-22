@testitem "fit_cover: the requested size is exact" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 3000, 4000)
    for (w, h) in ((1920, 1080), (5120, 2880), (2880, 1864))
        @test size(fit_cover(img, w, h)) == (h, w)
    end
end

@testitem "fit_cover: the crop is centred" begin
    using ImageCore
    # A central red band on black, 4:3 source to a 16:9 target: the cover
    # crop trims top and bottom, so the band must survive.
    img = fill(RGB{N0f8}(0, 0, 0), 300, 400)
    img[141:160, :] .= RGB{N0f8}(1, 0, 0)
    out = fit_cover(img, 320, 180)
    @test red(out[90, 160]) > 0.5
end

@testitem "fit_cover: values stay within [0, 1]" begin
    using ImageCore
    # Lanczos rings past [0, 1]; without clamping, the conversion to N0f8
    # throws. Worst case: a high-contrast checkerboard, which maximises the
    # overshoot.
    img = [RGB{N0f8}(iseven(i + j) ? 1 : 0, iseven(i + j) ? 1 : 0,
                     iseven(i + j) ? 1 : 0) for i in 1:200, j in 1:200]
    out = fit_cover(img, 97, 61)
    @test all(0 .<= Float64.(channelview(out)) .<= 1)
end

@testitem "fit_cover: downscaling does not alias" begin
    using ImageCore, Statistics
    # A 1px checkerboard on 800x800: interpolation without prefiltering would
    # sample every eighth pixel and return a flat black or white field (or
    # moiré). A correct reduction averages towards mid grey.
    img = [RGB{N0f8}(iseven(i + j), iseven(i + j), iseven(i + j))
           for i in 1:800, j in 1:800]
    out = fit_cover(img, 100, 100)
    m = mean(Float64.(channelview(out)))
    @test 0.4 < m < 0.6
    # And the spread must collapse: no checkerboard left, just flat grey.
    @test std(Float64.(channelview(out))) < 0.15
end

@testitem "fit_cover: an image already at format keeps its size" begin
    using ImageCore, Random
    img = rand(MersenneTwister(2), RGB{N0f8}, 108, 192)
    @test size(fit_cover(img, 192, 108)) == (108, 192)
end

@testitem "fit_cover: invalid dimensions are rejected" begin
    using ImageCore
    img = fill(RGB{N0f8}(0, 0, 0), 10, 10)
    @test_throws ArgumentError fit_cover(img, 0, 10)
    @test_throws ArgumentError fit_cover(img, 10, -5)
end
