@testitem "watercolour validates and renders deterministic washes" begin
    using ImageCore

    @test_throws ArgumentError Watercolour(radius = 0)
    @test_throws ArgumentError Watercolour(bleeding = -0.1)
    @test_throws ArgumentError Watercolour(granulation = 1.1)
    @test_throws ArgumentError Watercolour(paper = -0.1)

    img = fill(RGB{N0f8}(0.4, 0.6, 0.8), 24, 32)
    effect = Watercolour(
        radius = 3, bleeding = 0.5, granulation = 0.12, paper = 0.1, seed = 7)
    first_render = apply(effect, img)
    second_render = apply(effect, img)

    @test first_render == second_render
    @test size(first_render) == size(img)
    @test eltype(first_render) == eltype(img)
    @test length(unique(first_render)) > 1
    @test sum(Gray.(first_render)) / length(img) >
          sum(Gray.(img)) / length(img)
end

@testitem "watercolour bleeding softens a hard edge" begin
    using ImageCore

    img = fill(Gray{N0f8}(0), 21, 31)
    img[:, 17:end] .= Gray{N0f8}(1)
    dry = apply(
        Watercolour(
            radius = 3, bleeding = 0, granulation = 0, paper = 0), img)
    wet = apply(
        Watercolour(
            radius = 3, bleeding = 1, granulation = 0, paper = 0), img)

    @test dry == img
    @test 0 < wet[11, 16] < 1
    @test 0 < wet[11, 17] < 1
end
