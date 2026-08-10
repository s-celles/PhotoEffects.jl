@testitem "ReactionDiffusion uses periodic Gray-Scott boundaries" begin
    u = ones(8, 10)
    v = zeros(8, 10)
    v[1, 1] = 1
    next_u = similar(u)
    next_v = similar(v)
    effect = ReactionDiffusion(iterations = 1, dt = 0.2,
        diffusion_u = 0.16, diffusion_v = 0.08)

    PhotoEffects._gray_scott_step!(next_u, next_v, u, v, effect)
    @test next_v[1, end] > 0
    @test next_v[end, 1] > 0
    @test all(value -> 0 <= value <= 1, next_u)
    @test all(value -> 0 <= value <= 1, next_v)
end

@testitem "ReactionDiffusion creates deterministic photo-tinted patterns" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.8, 0.2, 0.1), 48, 64)
    image[:, 33:end] .= RGB{N0f8}(0.1, 0.25, 0.85)
    effect = ReactionDiffusion(iterations = 35, spots = 8, seed = 13)
    first_render = apply(effect, image)

    @test first_render == apply(effect, image)
    @test first_render != image
    @test size(first_render) == size(image)
    @test sum(red, first_render[:, 1:32]) > sum(blue, first_render[:, 1:32])
    @test sum(blue, first_render[:, 33:end]) > sum(red, first_render[:, 33:end])
end

@testitem "ReactionDiffusion validates kinetics and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(ReactionDiffusion(iterations = 3, spots = 2), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError ReactionDiffusion(iterations = 0)
    @test_throws ArgumentError ReactionDiffusion(spots = 0)
    @test_throws ArgumentError ReactionDiffusion(feed = -0.1)
    @test_throws ArgumentError ReactionDiffusion(kill = 1.1)
    @test_throws ArgumentError ReactionDiffusion(diffusion_u = 0)
    @test_throws ArgumentError ReactionDiffusion(dt = 0)
end
