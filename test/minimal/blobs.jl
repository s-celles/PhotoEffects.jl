@testitem "Blobs keeps palette mood rather than spatial layout" begin
    using ImageCore

    colours = [RGB{N0f8}(0.1, 0.2, 0.7), RGB{N0f8}(0.9, 0.6, 0.15)]
    striped = Matrix{RGB{N0f8}}(undef, 48, 64)
    striped[:, 1:32] .= colours[1]
    striped[:, 33:end] .= colours[2]
    shuffled = reshape(reverse(vec(striped)), size(striped))
    effect = Blobs(colors = 2, blobs = 6, radius = 18, seed = 23)

    first_render = apply(effect, striped)
    @test first_render == apply(effect, striped)
    @test first_render == apply(effect, shuffled)
    @test size(first_render) == size(striped)
    @test length(unique(first_render)) > 2
end

@testitem "Blobs preserves a flat colour" begin
    using ImageCore

    colour = RGB{N0f8}(0.25, 0.45, 0.65)
    image = fill(colour, 30, 42)
    @test all(apply(Blobs(colors = 4, blobs = 5), image) .== colour)
end

@testitem "Blobs validates parameters and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(Blobs(colors = 2, blobs = 3), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Blobs(colors = 1)
    @test_throws ArgumentError Blobs(blobs = 0)
    @test_throws ArgumentError Blobs(radius = 0)
    @test_throws ArgumentError Blobs(iterations = 0)
end
