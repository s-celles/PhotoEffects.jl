@testitem "Pointillism paints deterministic varying dots" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.2, 0.5, 0.8), 64, 96)
    paper = RGB{N0f8}(0.96, 0.94, 0.88)
    effect = Pointillism(points = 80, min_radius = 1,
        max_radius = 4, seed = 17, background = paper)
    first_render = apply(effect, image)

    @test first_render == apply(effect, image)
    @test size(first_render) == size(image)
    @test Set(first_render) == Set((image[1], paper))
    @test 80 < count(!=(paper), first_render) < length(image)
end

@testitem "Pointillism density follows image detail" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.1, 0.1, 0.1), 60, 80)
    image[:, 38:42] .= RGB{N0f8}(0.9, 0.9, 0.9)
    effect = Pointillism(points = 120, min_radius = 1,
        max_radius = 1, detail = 2, background_weight = 0.1, seed = 5)
    result = apply(effect, image)
    paper = effect.background

    @test count(!=(paper), result[:, 34:46]) >
          count(!=(paper), result[:, 1:13])
end

@testitem "Pointillism validates parameters and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(Pointillism(points = 20), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Pointillism(points = 0)
    @test_throws ArgumentError Pointillism(min_radius = 0)
    @test_throws ArgumentError Pointillism(min_radius = 4, max_radius = 3)
    @test_throws ArgumentError Pointillism(detail = -1)
    @test_throws ArgumentError Pointillism(background_weight = -1)
end
