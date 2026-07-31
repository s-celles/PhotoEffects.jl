@testitem "apply: preserves opaque input colour models" begin
    using Colors: HSV, Lab
    using ImageCore

    gray = fill(Gray{Float32}(0.4), 24, 32)
    hsv = fill(HSV{Float32}(210, 0.5, 0.7), 24, 32)
    lab = fill(Lab{Float32}(55, 12, -18), 24, 32)

    @test eltype(apply(Oil(radius = 1), gray)) == Gray{Float32}
    @test eltype(apply(Oil(radius = 1), hsv)) == HSV{Float32}
    @test eltype(apply(Oil(radius = 1), lab)) == Lab{Float32}
end

@testitem "apply: preserves transparency" begin
    using ImageCore

    img = [RGBA{Float32}(0.2, 0.4, 0.8, (x + y) / 20)
           for y in 1:8, x in 1:10]
    out = apply(Posterize(levels = 3), img)

    @test eltype(out) == RGBA{Float32}
    @test alpha.(out) == alpha.(img)
end

@testitem "apply: intrinsically coloured effects colour grayscale inputs" begin
    using ImageCore

    img = reshape(Gray{Float32}.(range(0, 1; length = 16)), 4, 4)
    @test eltype(apply(Duotone(), img)) == RGB{N0f8}
end

@testitem "apply: output type can be selected explicitly" begin
    using Colors: Lab
    using ImageCore

    img = fill(RGB{N0f8}(0.2, 0.4, 0.8), 12, 16)
    out = apply(Posterize(levels = 3), img; output_type = Lab{Float32})
    @test eltype(out) == Lab{Float32}
end
