@testitem "LowPoly: size is preserved" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 120, 200)
    @test size(apply(LowPoly(points = 200), img)) == (120, 200)
end

@testitem "LowPoly: the whole image is covered" begin
    using ImageCore
    # A uniform image must come out uniform: were a single pixel left
    # unpainted it would be black and this test would fail. That is the
    # coverage check on the triangulation — the border frame exists exactly
    # so the convex hull reaches the corners.
    img = fill(RGB{N0f8}(0.35, 0.55, 0.25), 150, 240)
    @test all(apply(LowPoly(points = 150), img) .== img[1, 1])
end

@testitem "LowPoly: facets are flat" begin
    using ImageCore, Random
    img = rand(MersenneTwister(2), RGB{N0f8}, 100, 100)
    out = apply(LowPoly(points = 120), img)
    # The noisy input holds ~10 000 distinct colours; the output must hold
    # only a handful — at most one per facet.
    @test length(unique(out)) < length(unique(img)) ÷ 10
end

@testitem "LowPoly: more points, more facets" begin
    using ImageCore, Random
    img = rand(MersenneTwister(3), RGB{N0f8}, 128, 128)
    @test length(unique(apply(LowPoly(points = 400), img))) >
          length(unique(apply(LowPoly(points = 80), img)))
end

@testitem "LowPoly: deterministic for equal seeds" begin
    using ImageCore, Random
    img = rand(MersenneTwister(4), RGB{N0f8}, 96, 96)
    e = LowPoly(points = 150)
    @test apply(e, img) == apply(e, img)
end

@testitem "LowPoly: different seeds, different renders" begin
    using ImageCore, Random
    img = rand(MersenneTwister(5), RGB{N0f8}, 96, 96)
    a = apply(LowPoly(points = 150, seed = 1), img)
    b = apply(LowPoly(points = 150, seed = 2), img)
    @test a != b
end

@testitem "LowPoly: invalid parameters are rejected" begin
    @test_throws ArgumentError LowPoly(points = 2)
    @test_throws ArgumentError LowPoly(detail = -1.0)
end
