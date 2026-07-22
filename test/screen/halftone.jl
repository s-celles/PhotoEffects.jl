@testitem "Halftone: size is preserved" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 60, 90)
    @test size(apply(Halftone(cell = 6), img)) == (60, 90)
end

@testitem "Halftone: only two inks come out" begin
    using ImageCore, Random
    # A halftone screen is bi-level by definition: it simulates greys through
    # dot area, not through intermediate tones. Any third colour would mean
    # the screen is not actually screening.
    img = rand(MersenneTwister(2), RGB{N0f8}, 96, 96)
    out = apply(Halftone(cell = 6), img)
    @test length(unique(out)) <= 2
end

@testitem "Halftone: white paper stays blank" begin
    using ImageCore
    out = apply(Halftone(cell = 6), fill(RGB{N0f8}(1, 1, 1), 64, 64))
    @test all(out .== RGB{N0f8}(1, 1, 1))
end

@testitem "Halftone: black floods with ink" begin
    using ImageCore, Statistics
    out = apply(Halftone(cell = 6), fill(RGB{N0f8}(0, 0, 0), 64, 64))
    ink = mean(out .== RGB{N0f8}(0, 0, 0))
    @test ink > 0.9
end

@testitem "Halftone: ink coverage grows as the image darkens" begin
    using ImageCore, Statistics
    e = Halftone(cell = 8)
    coverage(v) = mean(apply(e, fill(RGB{N0f8}(v, v, v), 96, 96)) .==
                       RGB{N0f8}(0, 0, 0))
    @test issorted([coverage(v) for v in (1.0, 0.8, 0.6, 0.4, 0.2, 0.0)])
end

@testitem "Halftone: a cell reads its whole area, not just its centre" begin
    using ImageCore, Random, Statistics
    # Grain that averages to a mid grey. Sampling one pixel per cell lets the
    # noise set each dot size independently; integrating the cell must not.
    rng = MersenneTwister(7)
    v = [clamp(0.5 + 0.35 * randn(rng), 0, 1) for _ in 1:128, _ in 1:128]
    noisy = RGB{N0f8}.(v, v, v)
    flat = fill(RGB{N0f8}(0.5, 0.5, 0.5), 128, 128)
    e = Halftone(cell = 8)
    cov(img) = mean(apply(e, img) .== RGB{N0f8}(0, 0, 0))
    # Averaging pulls the screened grain back onto the tone it averages to.
    @test abs(cov(noisy) - cov(flat)) < 0.06
end

@testitem "Halftone: gamma opens the highlights without touching the ends" begin
    using ImageCore, Statistics
    cov(g, v) = mean(apply(Halftone(cell = 8, gamma = g),
                           fill(RGB{N0f8}(v, v, v), 96, 96)) .==
                     RGB{N0f8}(0, 0, 0))
    # A midtone screens lighter as gamma rises...
    @test cov(2.2, 0.5) < cov(1.0, 0.5)
    # ...while paper stays blank and ink stays solid whatever gamma does.
    @test cov(2.2, 1.0) == cov(1.0, 1.0) == 0
    @test cov(2.2, 0.0) == cov(1.0, 0.0) == 1
end

@testitem "Halftone: custom inks are honoured" begin
    using ImageCore, Random
    ink, paper = RGB{N0f8}(0.1, 0.0, 0.5), RGB{N0f8}(0.98, 0.96, 0.9)
    out = apply(Halftone(cell = 6, ink = ink, paper = paper),
                rand(MersenneTwister(3), RGB{N0f8}, 64, 64))
    @test Set(unique(out)) ⊆ Set([ink, paper])
end

@testitem "Halftone: square shape also screens" begin
    using ImageCore, Statistics
    e = Halftone(cell = 8, shape = HalftoneShape.SQUARE)
    light = mean(apply(e, fill(RGB{N0f8}(0.8, 0.8, 0.8), 64, 64)) .==
                 RGB{N0f8}(0, 0, 0))
    dark = mean(apply(e, fill(RGB{N0f8}(0.2, 0.2, 0.2), 64, 64)) .==
                RGB{N0f8}(0, 0, 0))
    @test dark > light
end

@testitem "Halftone: the render is deterministic" begin
    using ImageCore, Random
    img = rand(MersenneTwister(4), RGB{N0f8}, 64, 64)
    e = Halftone(cell = 7)
    @test apply(e, img) == apply(e, img)
end

@testitem "HalftoneShape: the enum exposes DOT and SQUARE" begin
    @test HalftoneShape.DOT isa HalftoneShape.T
    @test HalftoneShape.SQUARE isa HalftoneShape.T
    @test HalftoneShape.DOT != HalftoneShape.SQUARE
end

@testitem "Halftone: invalid parameters are rejected" begin
    @test_throws ArgumentError Halftone(cell = 1)
end
