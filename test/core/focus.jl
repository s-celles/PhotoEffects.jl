@testitem "Vignette darkens corners while retaining the centre" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.8, 0.6, 0.4), 61, 81)
    result = apply(Vignette(strength = 0.7, start = 0.35), image)

    @test Float64(Gray(result[1, 1])) < Float64(Gray(result[31, 41]))
    @test result[31, 41] == image[31, 41]
    @test apply(Vignette(strength = 0), image) == image
end

@testitem "Bloom spreads only bright highlights" begin
    using ImageCore

    image = fill(RGB{N0f8}(0, 0, 0), 41, 41)
    image[21, 21] = RGB{N0f8}(1, 1, 1)
    result = apply(Bloom(radius = 4, strength = 0.8, threshold = 0.7), image)

    @test result[21, 21] == image[21, 21]
    @test Float64(Gray(result[21, 23])) > 0
    @test result[1, 1] == image[1, 1]
    @test apply(Bloom(strength = 0), image) == image
end

@testitem "focus effects validate parameters and preserve alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    for effect in (Vignette(), Bloom())
        result = apply(effect, image)
        @test eltype(result) == RGBA{N0f8}
        @test all(alpha.(result) .== alpha(image[1]))
    end

    @test_throws ArgumentError Vignette(strength = -0.1)
    @test_throws ArgumentError Vignette(start = 1)
    @test_throws ArgumentError Bloom(radius = 0)
    @test_throws ArgumentError Bloom(strength = 1.1)
    @test_throws ArgumentError Bloom(threshold = -0.1)
end
