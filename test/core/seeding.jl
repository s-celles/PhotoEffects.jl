@testitem "edge_map: a uniform image gives zeros throughout" begin
    using ImageCore
    img = fill(RGB{N0f8}(0.4, 0.4, 0.4), 32, 32)
    @test all(PhotoEffects._edge_map(img) .== 0)
end

@testitem "edge_map: normalised to [0, 1]" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 64, 64)
    e = PhotoEffects._edge_map(img)
    @test all(0 .<= e .<= 1)
    @test maximum(e) ≈ 1
end

@testitem "edge_map: an edge stands out over a flat area" begin
    using ImageCore
    img = fill(RGB{N0f8}(0, 0, 0), 64, 64)
    img[:, 33:end] .= RGB{N0f8}(1, 1, 1)
    e = PhotoEffects._edge_map(img)
    @test maximum(e[:, 30:35]) > 10 * maximum(e[:, 5:15])
end

@testitem "sample_points: count and domain are respected" begin
    using ImageCore, StableRNGs
    e = fill(0.5, 40, 60)
    pts = PhotoEffects._sample_points(e, 100, StableRNG(1), 2.5)
    @test length(pts) == 100
    @test all(1 <= p[1] <= 60 for p in pts)   # x = column
    @test all(1 <= p[2] <= 40 for p in pts)   # y = row
end

@testitem "sample_points: without replacement" begin
    using StableRNGs
    e = fill(0.5, 20, 20)
    pts = PhotoEffects._sample_points(e, 200, StableRNG(2), 2.5)
    @test length(unique(pts)) == 200
end

@testitem "sample_points: seeds concentrate along edges" begin
    using StableRNGs, Statistics
    # A sharp vertical edge down the middle: with a low uniform floor, most
    # seeds must land in the central band rather than spread uniformly.
    e = fill(0.0, 100, 100)
    e[:, 48:52] .= 1.0
    pts = PhotoEffects._sample_points(e, 300, StableRNG(3), 3.0; background = 0.05)
    in_band = count(p -> 48 <= p[1] <= 52, pts)
    @test in_band > 150   # ~5 % of the area, > 50 % of the seeds
end

@testitem "sample_points: background sets the share drawn uniformly" begin
    using StableRNGs, Statistics
    # The floor carries background/(1+background) of the weight, so raising it
    # must pull the draw back towards the area share whatever the map holds.
    e = fill(0.0, 100, 100)
    e[:, 48:52] .= 1.0
    # 400 draws against the band's 500 pixels: sampling is without replacement,
    # so asking for more would cap the share at the band's own area and measure
    # that ceiling instead of the concentration.
    band(bg) = count(p -> 48 <= p[1] <= 52,
                     PhotoEffects._sample_points(e, 400, StableRNG(3), 3.0;
                                                 background = bg)) / 400
    shares = [band(bg) for bg in (0.05, 0.5, 5.0, 50.0)]
    @test issorted(shares; rev = true)      # more floor, less concentration
    @test shares[1] > 0.5                   # a low floor really concentrates
    @test shares[end] < 0.12                # a high one lands near the 5 % area
end

@testitem "edge_map: one extreme edge does not crush the rest" begin
    using ImageCore, Statistics
    include(joinpath(@__DIR__, "seeding_helpers.jl"))
    e = PhotoEffects._edge_map(_graded_image())
    # The band carries genuine detail. Scaling by the outlier's magnitude
    # instead of a quantile would flatten it to near zero and hand the seeding
    # over to the uniform background term.
    @test median(e[:, BAND]) > 0.5
    @test median(e[:, 5:45]) < 0.1     # the flat field stays flat
end

@testitem "sample_points: concentration grows with detail" begin
    using ImageCore, StableRNGs, Statistics
    include(joinpath(@__DIR__, "seeding_helpers.jl"))
    e = PhotoEffects._edge_map(_graded_image())
    # The share landing in the band rises with `detail` only up to the peak
    # near 2. Past it the exponent hands the edge term to the few saturated
    # pixels — here the outlier spot, which sits outside the band — and the
    # share falls again. Averaged over seeds: single draws are too noisy to
    # separate the plateau from the decline.
    share(d, bg) = mean([count(p -> p[1] in BAND,
                               PhotoEffects._sample_points(e, 2000, StableRNG(s), d;
                                                           background = bg)) / 2000
                         for s in 1:5])
    rising = [share(d, 0.2) for d in (0.5, 1.0, 2.0)]
    @test issorted(rising)
    @test rising[1] > BAND_AREA        # already above a uniform draw
    # And the documented decline past the peak, which is why 2 is the ceiling.
    @test share(8.0, 0.2) < share(2.0, 0.2)
end

@testitem "sample_points: deterministic for equal seeds" begin
    using StableRNGs
    e = rand(StableRNG(9), 50, 50)
    a = PhotoEffects._sample_points(e, 80, StableRNG(4), 2.0)
    b = PhotoEffects._sample_points(e, 80, StableRNG(4), 2.0)
    @test a == b
end
