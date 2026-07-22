@testitem "Duotone: size is preserved" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 60, 90)
    @test size(apply(Duotone(), img)) == (60, 90)
end

@testitem "Duotone: black maps to the first stop, white to the last" begin
    using ImageCore
    shadow, highlight = RGB{N0f8}(0.1, 0.0, 0.3), RGB{N0f8}(1.0, 0.9, 0.6)
    e = Duotone([shadow, highlight])
    @test apply(e, fill(RGB{N0f8}(0, 0, 0), 8, 8))[1] == shadow
    @test apply(e, fill(RGB{N0f8}(1, 1, 1), 8, 8))[1] == highlight
end

@testitem "Duotone: every output sits on the ramp" begin
    using ImageCore, Random
    # With two stops the gradient is a segment in RGB space: each output
    # colour must be a convex combination of the two ends. That is what makes
    # a duotone read as a single ink pair rather than a tinted photo.
    shadow, highlight = RGB{Float64}(0.0, 0.1, 0.4), RGB{Float64}(1.0, 0.8, 0.2)
    out = apply(Duotone([shadow, highlight]),
                rand(MersenneTwister(2), RGB{N0f8}, 40, 40))
    for c in unique(out)
        t = (red(c) - red(shadow)) / (red(highlight) - red(shadow))
        @test 0 - 1e-2 <= t <= 1 + 1e-2
        @test isapprox(green(c), green(shadow) + t * (green(highlight) - green(shadow));
                       atol = 0.02)
        @test isapprox(blue(c), blue(shadow) + t * (blue(highlight) - blue(shadow));
                       atol = 0.02)
    end
end

@testitem "Duotone: brighter in, brighter out" begin
    using ImageCore
    e = Duotone()
    ramp = [Float64(green(apply(e, fill(RGB{N0f8}(v, v, v), 4, 4))[1]))
            for v in 0.0:0.05:1.0]
    @test issorted(ramp)
end

@testitem "Duotone: a uniform image stays uniform" begin
    using ImageCore
    out = apply(Duotone(), fill(RGB{N0f8}(0.3, 0.6, 0.2), 20, 20))
    @test length(unique(out)) == 1
end

@testitem "Duotone: three stops pass through the midtone" begin
    using ImageCore
    mid = RGB{N0f8}(0.8, 0.2, 0.2)
    e = Duotone([RGB{N0f8}(0, 0, 0), mid, RGB{N0f8}(1, 1, 1)])
    out = apply(e, fill(RGB{N0f8}(0.5, 0.5, 0.5), 4, 4))
    @test red(out[1]) > 0.6   # clearly tinted, not neutral grey
    @test green(out[1]) < 0.5
end

@testitem "Duotone: invalid parameters are rejected" begin
    using ImageCore
    @test_throws ArgumentError Duotone([RGB{N0f8}(0, 0, 0)])
    @test_throws ArgumentError Duotone(RGB{N0f8}[])
end
