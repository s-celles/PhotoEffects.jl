@testitem "Cubist renders deterministic shifted convex cells" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.45, 0.55, 0.65), 72, 96)
    effect = Cubist(points = 36, shift = 0.2, seed = 41)
    first_render = apply(effect, image)

    @test first_render == apply(effect, image)
    @test size(first_render) == size(image)
    @test 1 < length(unique(first_render)) <= 36
end

@testitem "Cubist with zero shift is its Voronoi geometry" begin
    using ImageCore, Random

    image = rand(MersenneTwister(81), RGB{N0f8}, 48, 64)
    cubist = apply(Cubist(points = 24, shift = 0, seed = 7), image)
    voronoi = apply(
        Voronoi(points = 24, detail = 0,
            background = 1, seed = 7), image)

    @test cubist == voronoi
end

@testitem "Cubist preserves non-RGB colour and alpha contracts" begin
    using ImageCore

    gray = fill(Gray{N0f8}(0.5), 24, 32)
    transparent = fill(RGBA{N0f8}(0.3, 0.5, 0.7, 0.4), 24, 32)

    @test eltype(apply(Cubist(points = 12), gray)) == Gray{N0f8}
    result = apply(Cubist(points = 12), transparent)
    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(transparent[1]))

    @test_throws ArgumentError Cubist(points = 0)
    @test_throws ArgumentError Cubist(shift = -0.1)
    @test_throws ArgumentError Cubist(shift = 1.1)
end
