@testitem "Grain adds deterministic zero-centred texture" begin
    using ImageCore, Statistics

    image = fill(RGB{N0f8}(0.5, 0.5, 0.5), 80, 100)
    effect = Grain(amount = 0.12, seed = 31)
    first_render = apply(effect, image)

    @test first_render == apply(effect, image)
    @test first_render != image
    @test abs(mean(Float64.(Gray.(first_render))) - 0.5) < 0.02
    @test length(unique(first_render)) > 20
end

@testitem "zero Grain is identity across colour models" begin
    using ImageCore, Random

    rgb = rand(MersenneTwister(9), RGB{N0f8}, 20, 30)
    gray = Gray{N0f8}.(rgb)
    @test apply(Grain(amount = 0), rgb) == rgb
    @test apply(Grain(amount = 0), gray) == gray
end

@testitem "Grain validates amount and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(Grain(amount = 0.1), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Grain(amount = -0.1)
    @test_throws ArgumentError Grain(amount = 1.1)
end
