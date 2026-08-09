@testitem "TspArt builds a deterministic single tour" begin
    using ImageCore

    image = fill(Gray{N0f8}(1), 50, 70)
    image[:, 36:end] .= Gray{N0f8}(0.1)
    effect = TspArt(points = 90, width = 1, optimize = 1, seed = 17)
    stipples = PhotoEffects._tsp_stipples(effect, RGB{N0f8}.(image))
    tour = PhotoEffects._tsp_tour(stipples, effect.optimize)

    @test length(stipples) == 90
    @test length(tour) == length(stipples)
    @test Set(tour) == Set(stipples)
    @test count(point -> point[1] > 35, stipples) > 70
    @test tour == PhotoEffects._tsp_tour(stipples, effect.optimize)
end

@testitem "TspArt renders only one continuous-path palette" begin
    using ImageCore

    image = fill(Gray{N0f8}(0.15), 48, 64)
    effect = TspArt(points = 70, width = 2, seed = 29)
    first_render = apply(effect, image)

    @test first_render == apply(effect, image)
    @test size(first_render) == size(image)
    @test Set(first_render) == Set((effect.ink, effect.paper))
    @test count(==(effect.ink), first_render) > effect.points
    @test all(apply(effect, fill(Gray{N0f8}(1), 20, 30)) .== effect.paper)
end

@testitem "TspArt validates parameters and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(TspArt(points = 20), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError TspArt(points = 1)
    @test_throws ArgumentError TspArt(width = 0)
    @test_throws ArgumentError TspArt(optimize = -1)
end
