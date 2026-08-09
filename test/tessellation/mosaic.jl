@testitem "PixelMosaic paints clipped blocks with their mean" begin
    using ImageCore

    img = reshape(RGB{N0f8}.(Gray.(range(0, 1; length = 63))), 7, 9)
    result = apply(PixelMosaic(block = 4), img)

    @test size(result) == size(img)
    @test length(unique(result[1:4, 1:4])) == 1
    @test result[1, 1] == RGB{N0f8}(sum(img[1:4, 1:4]) / 16)
    @test length(unique(result)) == 6
end

@testitem "PixelMosaic supports tile joints" begin
    using ImageCore

    img = fill(RGB{N0f8}(0.4, 0.6, 0.8), 12, 12)
    joint_color = RGB{N0f8}(0.95, 0.9, 0.8)
    result = apply(
        PixelMosaic(
            block = 5, joint = 1, joint_color = joint_color), img)

    @test count(==(joint_color), result) > 0
    @test count(==(img[1]), result) > 0
    @test_throws ArgumentError PixelMosaic(block = 0)
    @test_throws ArgumentError PixelMosaic(block = 4, joint = 4)
end

@testitem "HexMosaic forms deterministic flat honeycomb cells" begin
    using ImageCore, Random

    img = rand(MersenneTwister(21), RGB{N0f8}, 48, 72)
    effect = HexMosaic(cell = 6)
    first_render = apply(effect, img)

    @test first_render == apply(effect, img)
    @test size(first_render) == size(img)
    @test length(unique(first_render)) < length(img) ÷ 4
    @test_throws ArgumentError HexMosaic(cell = 1)
end

@testitem "HexMosaic preserves a flat image" begin
    using ImageCore

    img = fill(Gray{N0f8}(0.35), 35, 53)
    @test all(apply(HexMosaic(cell = 5), img) .== img[1])
end
