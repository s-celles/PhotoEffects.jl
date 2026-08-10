@testitem "Glitch sorts thresholded pixel runs" begin
    using ImageCore

    row = RGB{N0f8}.(Gray.([0.1, 0.8, 0.6, 0.9, 0.2]))
    PhotoEffects._sort_glitch_runs!(row, 0.5, 2)

    @test Float64.(Gray.(row))≈[0.1, 0.6, 0.8, 0.9, 0.2] atol=1 / 255
end

@testitem "Glitch combines deterministic channel and slice displacement" begin
    using ImageCore

    image = [RGB{N0f8}(x / 16, y / 12, (x + y) / 28)
             for y in 1:12, x in 1:16]
    effect = Glitch(channel_offset = 2, slices = 4, displacement = 5,
        threshold = 1, seed = 17)
    rendered = apply(effect, image)

    @test rendered == apply(effect, image)
    @test size(rendered) == size(image)
    @test rendered != image
    @test any(red.(rendered) .!= red.(image))
    @test any(blue.(rendered) .!= blue.(image))
end

@testitem "Glitch has an identity setting and validates parameters" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 8, 12)
    identity = Glitch(channel_offset = 0, slices = 0, displacement = 0,
        threshold = 1)
    result = apply(identity, image)

    @test result == image
    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Glitch(channel_offset = -1)
    @test_throws ArgumentError Glitch(slices = -1)
    @test_throws ArgumentError Glitch(displacement = -1)
    @test_throws ArgumentError Glitch(threshold = -0.1)
    @test_throws ArgumentError Glitch(threshold = 1.1)
    @test_throws ArgumentError Glitch(min_run = 1)
end
