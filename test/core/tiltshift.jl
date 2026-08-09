@testitem "TiltShift keeps its focus band and blurs the periphery" begin
    using ImageCore

    image = fill(RGB{N0f8}(0, 0, 0), 61, 61)
    image[31, 31] = RGB{N0f8}(1, 1, 1)
    image[5, 31] = RGB{N0f8}(1, 1, 1)
    effect = TiltShift(radius = 4, focus = 0.5, band = 0.2,
        transition = 0.15)
    result = apply(effect, image)

    @test result[31, 31] == image[31, 31]
    @test result[31, 33] == image[31, 33]
    @test Float64(Gray(result[5, 31])) < 1
    @test Float64(Gray(result[5, 33])) > 0
end

@testitem "TiltShift preserves flat images and alpha" begin
    using ImageCore

    flat = fill(RGB{N0f8}(0.3, 0.5, 0.7), 30, 40)
    @test all(apply(TiltShift(radius = 3), flat) .== flat[1])

    transparent = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(TiltShift(), transparent)
    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(transparent[1]))
end

@testitem "TiltShift validates its normalized focus geometry" begin
    @test_throws ArgumentError TiltShift(radius = 0)
    @test_throws ArgumentError TiltShift(focus = -0.1)
    @test_throws ArgumentError TiltShift(focus = 1.1)
    @test_throws ArgumentError TiltShift(band = 0)
    @test_throws ArgumentError TiltShift(band = 1.1)
    @test_throws ArgumentError TiltShift(transition = 0)
end
