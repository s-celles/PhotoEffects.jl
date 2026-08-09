@testitem "Contour draws iso-luminance boundaries" begin
    using ImageCore

    image = repeat(reshape(Gray{N0f8}.(range(0, 1; length = 64)), 1, :), 40, 1)
    ink = RGB{N0f8}(0.1, 0.2, 0.3)
    paper = RGB{N0f8}(0.95, 0.9, 0.8)
    result = apply(
        Contour(levels = 5, width = 1,
            line_color = ink, background = paper),
        image)

    @test size(result) == size(image)
    @test eltype(result) == RGB{N0f8}
    @test Set(result) == Set((ink, paper))
    @test all(count(==(ink), result[:, column]) in (0, size(image, 1))
    for column in axes(result, 2))
end

@testitem "Contour leaves a flat field as paper" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.4, 0.4, 0.4), 24, 32)
    effect = Contour(levels = 6, background = RGB(0.9, 0.8, 0.7))
    result = apply(effect, image)

    @test all(result .== effect.background)
    @test_throws ArgumentError Contour(levels = 1)
    @test_throws ArgumentError Contour(width = 0)
end

@testitem "Contour preserves transparent alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.4, 0.5, 0.6, 0.3), 12, 16)
    result = apply(Contour(), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
end
