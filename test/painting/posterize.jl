@testitem "Posterize: size is preserved" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 60, 90)
    @test size(apply(Posterize(levels = 5), img)) == (60, 90)
end

@testitem "Posterize: the palette is bounded by levels³" begin
    using ImageCore, Random
    img = rand(MersenneTwister(2), RGB{N0f8}, 128, 128)
    for n in (2, 4, 8)
        @test length(unique(apply(Posterize(levels = n), img))) <= n^3
    end
end

@testitem "Posterize: idempotent without smoothing" begin
    using ImageCore, Random
    # Quantisation lands on a fixed grid, so re-applying must change nothing.
    # If it did, the bands would drift with every pass. Only the unsmoothed
    # path is pointwise, and only a pointwise map can promise this.
    img = rand(MersenneTwister(3), RGB{N0f8}, 64, 64)
    e = Posterize(levels = 5, smoothing = 0)
    once = apply(e, img)
    @test apply(e, once) == once
end

@testitem "Posterize: smoothing flattens the speckle in a noisy gradient" begin
    using ImageCore, Random
    # A smooth ramp plus grain: pointwise snapping scatters the pixels either
    # side of each threshold, so neighbours disagree all over the band.
    rng = MersenneTwister(11)
    ramp = [clamp(x / 96 + 0.06 * randn(rng), 0, 1) for _ in 1:96, x in 1:96]
    img = RGB{N0f8}.(ramp, ramp, ramp)
    flips(out) = count(out[:, 1:(end - 1)] .!= out[:, 2:end])
    rough = apply(Posterize(levels = 5, smoothing = 0), img)
    smooth = apply(Posterize(levels = 5, smoothing = 1), img)
    @test flips(smooth) < flips(rough) / 2
end

@testitem "Posterize: smoothing keeps the palette on the grid" begin
    using ImageCore, Random
    img = rand(MersenneTwister(5), RGB{N0f8}, 48, 48)
    out = apply(Posterize(levels = 4, smoothing = 2), img)
    grid = Set(RGB{N0f8}(r, g, b)
               for r in 0:(1 / 3):1, g in 0:(1 / 3):1, b in 0:(1 / 3):1)
    @test issubset(Set(unique(out)), grid)
end

@testitem "Posterize: order is preserved" begin
    using ImageCore
    e = Posterize(levels = 4)
    ramp = [Float64(green(apply(e, fill(RGB{N0f8}(v, v, v), 4, 4))[1]))
            for v in 0.0:0.02:1.0]
    @test issorted(ramp)
end

@testitem "Posterize: the extremes are reached" begin
    using ImageCore
    e = Posterize(levels = 4)
    @test apply(e, fill(RGB{N0f8}(0, 0, 0), 4, 4))[1] == RGB{N0f8}(0, 0, 0)
    @test apply(e, fill(RGB{N0f8}(1, 1, 1), 4, 4))[1] == RGB{N0f8}(1, 1, 1)
end

@testitem "Posterize: more levels, more colours" begin
    using ImageCore, Random
    img = rand(MersenneTwister(4), RGB{N0f8}, 96, 96)
    @test length(unique(apply(Posterize(levels = 8), img))) >
          length(unique(apply(Posterize(levels = 3), img)))
end

@testitem "Posterize: outlines darken the edges" begin
    using ImageCore, Statistics
    img = fill(RGB{N0f8}(0.7, 0.7, 0.7), 64, 64)
    img[:, 33:end] .= RGB{N0f8}(0.2, 0.2, 0.2)
    plain = apply(Posterize(levels = 4), img)
    inked = apply(Posterize(levels = 4, outline = 0.2), img)
    mean_v(x) = mean(Float64.(channelview(x)))
    @test mean_v(inked) < mean_v(plain)
    # and the darkening must sit on the edge, not spread over the flats
    @test all(inked[:, 5:15] .== plain[:, 5:15])
end

@testitem "Posterize: invalid parameters are rejected" begin
    @test_throws ArgumentError Posterize(levels = 1)
    @test_throws ArgumentError Posterize(levels = 4, outline = -0.5)
    @test_throws ArgumentError Posterize(levels = 4, smoothing = -1)
end
