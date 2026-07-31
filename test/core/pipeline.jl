@testitem "Pipeline: effects are applied in order" begin
    using ImageCore

    img = reshape(
        RGB{N0f8}.([
            RGB(0.1, 0.2, 0.3),
            RGB(0.4, 0.5, 0.6),
            RGB(0.7, 0.8, 0.9),
            RGB(0.2, 0.4, 0.8)
        ]),
        2,
        2)
    first = Posterize(levels = 3)
    second = Duotone()

    @test apply(Pipeline(first, second), img) ==
          apply(second, apply(first, img))
end

@testitem "Pipeline: construction validates its stages" begin
    @test_throws ArgumentError Pipeline()
    @test Pipeline(Oil()) == Pipeline((Oil(),))
end
