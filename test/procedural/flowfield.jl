@testitem "FlowField follows a luminance gradient" begin
    using ImageCore

    image = repeat(reshape(Gray{N0f8}.(range(0, 1; length = 64)), 1, :), 40, 1)
    gray = Float64.(image)
    gradient_y, gradient_x = PhotoEffects.imgradients(
        gray, PhotoEffects.KernelFactors.sobel)
    effect = FlowField(particles = 20, steps = 6, step_size = 1,
        width = 1, seed = 5)
    path = PhotoEffects._flow_path(
        effect, gradient_x, gradient_y, (32.0, 20.0))

    @test length(path) == effect.steps + 1
    @test abs(path[end][1] - path[1][1]) >
          abs(path[end][2] - path[1][2])
end

@testitem "FlowField renders deterministic source-coloured trails" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.15, 0.3, 0.75), 48, 64)
    image[:, 33:end] .= RGB{N0f8}(0.9, 0.6, 0.15)
    effect = FlowField(particles = 80, steps = 8,
        step_size = 1.5, width = 2, seed = 19)
    first_render = apply(effect, image)

    @test first_render == apply(effect, image)
    @test size(first_render) == size(image)
    @test count(!=(effect.background), first_render) > effect.particles
    @test length(unique(first_render)) >= 3
end

@testitem "FlowField validates motion and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(FlowField(particles = 20, steps = 3), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError FlowField(particles = 0)
    @test_throws ArgumentError FlowField(steps = 0)
    @test_throws ArgumentError FlowField(step_size = 0)
    @test_throws ArgumentError FlowField(width = 0)
end
