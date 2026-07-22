@testitem "Oil: a uniform image is left untouched" begin
    using ImageCore
    img = fill(RGB{N0f8}(0.5, 0.2, 0.8), 64, 64)
    @test apply(Oil(radius = 4), img) == img
end

@testitem "Oil: a hard step stays hard" begin
    using ImageCore
    # This is THE property that separates Kuwahara from a blur: a blur would
    # average both sides of the edge and produce intermediate values. Here
    # not a single one may appear.
    img = fill(RGB{N0f8}(0, 0, 0), 64, 64)
    img[:, 33:end] .= RGB{N0f8}(1, 1, 1)
    out = apply(Oil(radius = 5), img)

    @test Set(unique(out)) ⊆ Set([RGB{N0f8}(0, 0, 0), RGB{N0f8}(1, 1, 1)])
    @test all(out[:, 32] .== RGB{N0f8}(0, 0, 0))   # step has not moved
    @test all(out[:, 33] .== RGB{N0f8}(1, 1, 1))
end

@testitem "Oil: noise is flattened" begin
    using ImageCore, Random, Statistics
    rng = MersenneTwister(42)
    img = RGB{N0f8}.(clamp01.(rand(rng, 64, 64) .* 0.3 .+ 0.4),
                     clamp01.(rand(rng, 64, 64) .* 0.3 .+ 0.4),
                     clamp01.(rand(rng, 64, 64) .* 0.3 .+ 0.4))
    out = apply(Oil(radius = 4), img)
    spread(x) = std(Float64.(channelview(x))[:])
    @test spread(out) < spread(img) / 2
end

@testitem "Oil: the render is deterministic" begin
    using ImageCore, Random
    rng = MersenneTwister(7)
    img = rand(rng, RGB{N0f8}, 48, 48)
    e = Oil(radius = 3, passes = 2)
    @test apply(e, img) == apply(e, img)
end

@testitem "Oil: more passes flatten further" begin
    using ImageCore, Random, Statistics
    rng = MersenneTwister(3)
    img = rand(rng, RGB{N0f8}, 96, 96)
    spread(x) = std(Float64.(channelview(x))[:])
    @test spread(apply(Oil(radius = 3, passes = 2), img)) <
          spread(apply(Oil(radius = 3, passes = 1), img))
end

@testitem "Oil: size is preserved" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 37, 53)  # odd dimensions
    @test size(apply(Oil(radius = 4), img)) == (37, 53)
end

@testitem "Oil: invalid parameters are rejected" begin
    @test_throws ArgumentError Oil(radius = -1)
    @test_throws ArgumentError Oil(passes = 0)
end

@testitem "Oil: a zero radius is the identity" begin
    using ImageCore, Random
    img = rand(MersenneTwister(9), RGB{N0f8}, 32, 32)
    @test apply(Oil(radius = 0), img) == img
end
