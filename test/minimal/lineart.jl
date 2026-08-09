@testitem "LineArt isolates a hard edge" begin
    using ImageCore

    image = fill(Gray{N0f8}(0.1), 48, 72)
    image[:, 37:end] .= Gray{N0f8}(0.9)
    ink = RGB{N0f8}(0.05, 0.08, 0.12)
    effect = LineArt(threshold = 0.3, width = 1, line_color = ink)
    result = apply(effect, image)

    @test size(result) == size(image)
    @test eltype(result) == RGB{N0f8}
    @test Set(result) == Set((ink, effect.background))
    ink_columns = findall(column -> any(==(ink), result[:, column]),
        axes(result, 2))
    @test !isempty(ink_columns)
    @test all(column -> 34 <= column <= 39, ink_columns)
end

@testitem "LineArt threshold controls retained detail" begin
    using ImageCore

    image = repeat(reshape(Gray{N0f8}.(range(0, 1; length = 80)), 1, :), 40, 1)
    low = LineArt(threshold = 0.05)
    high = LineArt(threshold = 0.8)

    @test count(==(low.line_color), apply(low, image)) >=
          count(==(high.line_color), apply(high, image))
    @test all(apply(LineArt(), fill(Gray{N0f8}(0.4), 20, 30)) .==
              LineArt().background)
end

@testitem "LineArt validates parameters and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(LineArt(), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError LineArt(threshold = -0.1)
    @test_throws ArgumentError LineArt(threshold = 1.1)
    @test_throws ArgumentError LineArt(width = 0)
end
