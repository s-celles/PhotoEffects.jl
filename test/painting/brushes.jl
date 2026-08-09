@testitem "Brushes renders deterministic gradient-oriented strokes" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.15, 0.25, 0.75), 64, 96)
    image[:, 48:end] .= RGB{N0f8}(0.9, 0.65, 0.15)
    effect = Brushes(strokes = 120, length = 11, width = 2,
        detail = 2, background_weight = 0.2, seed = 29)
    first_render = apply(effect, image)

    @test first_render == apply(effect, image)
    @test size(first_render) == size(image)
    @test count(!=(effect.background), first_render) > 120
    @test length(unique(first_render)) >= 3
end

@testitem "Brushes preserves a flat field on matching canvas" begin
    using ImageCore

    colour = RGB{N0f8}(0.35, 0.45, 0.55)
    image = fill(colour, 32, 48)
    effect = Brushes(strokes = 80, length = 7, width = 1,
        background = colour)

    @test all(apply(effect, image) .== colour)
end

@testitem "Brushes validates geometry and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.45), 20, 24)
    result = apply(Brushes(strokes = 20), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Brushes(strokes = 0)
    @test_throws ArgumentError Brushes(length = 0)
    @test_throws ArgumentError Brushes(width = 0)
    @test_throws ArgumentError Brushes(width = 6, length = 5)
end
