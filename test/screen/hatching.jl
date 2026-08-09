@testitem "Hatching density increases into shadow" begin
    using ImageCore

    image = fill(Gray{N0f8}(0.85), 60, 90)
    image[:, 46:end] .= Gray{N0f8}(0.15)
    ink = RGB{N0f8}(0.08, 0.09, 0.12)
    effect = Hatching(spacing = 6, width = 1, layers = 3,
        line_color = ink)
    result = apply(effect, image)

    @test size(result) == size(image)
    @test eltype(result) == RGB{N0f8}
    @test count(==(ink), result[:, 46:end]) >
          count(==(ink), result[:, 1:45])
    @test Set(result) == Set((ink, effect.background))
end

@testitem "Hatching leaves white paper blank" begin
    using ImageCore

    image = fill(Gray{N0f8}(1), 30, 40)
    effect = Hatching(spacing = 5, width = 2)

    @test all(apply(effect, image) .== effect.background)
end

@testitem "Hatching validates geometry and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.45), 20, 24)
    result = apply(Hatching(), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Hatching(spacing = 1)
    @test_throws ArgumentError Hatching(spacing = 4, width = 4)
    @test_throws ArgumentError Hatching(layers = 0)
    @test_throws ArgumentError Hatching(layers = 4)
    @test_throws ArgumentError Hatching(angle = Inf)
end
