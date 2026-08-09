@testitem "dither validates palettes and algorithms" begin
    using ImageCore

    @test_throws ArgumentError Dither(palette = [RGB(0, 0, 0)])
    @test_throws ArgumentError Dither(levels = 1)
    @test_throws ArgumentError Dither(levels = 257)

    @test Dither().method == DitherMethod.FLOYD_STEINBERG
    @test Dither(method = DitherMethod.BAYER).method == DitherMethod.BAYER
end

@testitem "dither restricts output to its palette" begin
    using ImageCore

    img = reshape(Gray{N0f8}.(range(0, 1; length = 256)), 16, 16)
    palette = [RGB(0.05, 0.1, 0.2), RGB(0.9, 0.8, 0.5)]

    for method in (DitherMethod.FLOYD_STEINBERG, DitherMethod.BAYER)
        result = apply(Dither(method = method, palette = palette), img)
        @test eltype(result) == RGB{N0f8}
        @test Set(result) <= Set(RGB{N0f8}.(palette))
        @test length(unique(result)) == 2
    end
end

@testitem "dither can generate a grayscale palette" begin
    using ImageCore

    img = reshape(Gray{N0f8}.(range(0, 1; length = 64)), 8, 8)
    result = apply(Dither(levels = 4), img)

    @test eltype(result) == Gray{N0f8}
    @test length(unique(result)) == 4
end
