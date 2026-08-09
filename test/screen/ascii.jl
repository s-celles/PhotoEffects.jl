@testitem "Ascii maps luminance to monotone glyph density" begin
    using ImageCore

    tones = Gray{N0f8}.(range(1, 0; length = 8))
    image = Matrix{Gray{N0f8}}(undef, 7, 40)
    for cell in 1:8
        image[:, (5cell - 4):(5cell)] .= tones[cell]
    end
    effect = Ascii(scale = 1)
    result = apply(effect, image)
    densities = [count(==(effect.ink), result[:, (5cell - 4):(5cell)])
                 for cell in 1:8]

    @test issorted(densities)
    @test first(densities) == 0
    @test last(densities) > 0
    @test length(unique(densities)) == 8
end

@testitem "Ascii uses a monospace bitmap and clips partial cells" begin
    using ImageCore

    white = fill(Gray{N0f8}(1), 15, 23)
    black = fill(Gray{N0f8}(0), 15, 23)
    effect = Ascii(scale = 2)

    @test all(apply(effect, white) .== effect.paper)
    result = apply(effect, black)
    @test size(result) == size(black)
    @test Set(result) == Set((effect.ink, effect.paper))
end

@testitem "Ascii validates scale and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(Ascii(), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Ascii(scale = 0)
end
