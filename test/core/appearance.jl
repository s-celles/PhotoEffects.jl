@testitem "twilight: the image is darkened" begin
    using ImageCore, Statistics
    img = fill(RGB{N0f8}(0.7, 0.78, 0.86), 32, 32)
    out = twilight(img)
    mean_v(x) = mean(Float64.(channelview(x)))
    @test mean_v(out) < mean_v(img) / 2
end

@testitem "twilight: hue is preserved" begin
    using ImageCore
    img = fill(RGB{N0f8}(0.16, 0.35, 0.78), 16, 16)  # blue
    h_in = HSV(img[1, 1]).h
    h_out = HSV(twilight(img)[1, 1]).h
    @test abs(h_out - h_in) < 2.0
end

@testitem "twilight: a twilight, not a switched-off screen" begin
    using ImageCore, Random, Statistics
    img = rand(MersenneTwister(4), RGB{N0f8}, 64, 64)
    @test mean(Float64.(channelview(twilight(img)))) > 0.02
end

@testitem "twilight: monotone in value" begin
    using ImageCore
    # Darkening harder must always give a darker image.
    img = fill(RGB{N0f8}(0.6, 0.6, 0.6), 8, 8)
    a = twilight(img; value = 0.5)
    b = twilight(img; value = 0.25)
    @test green(b[1, 1]) < green(a[1, 1])
end

@testitem "twilight: the shadows keep their separation" begin
    using ImageCore
    # The point of the shadow floor: dusk, not underexposure. Two distinct
    # dark tones must still be told apart after the remap.
    dark = twilight(fill(RGB{N0f8}(0.10, 0.10, 0.10), 4, 4))[1, 1]
    darker = twilight(fill(RGB{N0f8}(0.02, 0.02, 0.02), 4, 4))[1, 1]
    @test Float64(green(dark)) - Float64(green(darker)) > 0.01
end

@testitem "twilight: the shadow floor is honoured" begin
    using ImageCore
    # Pure black lands on the floor, not on black.
    lifted = twilight(fill(RGB{N0f8}(0, 0, 0), 4, 4); value = 0.5, shadow = 0.2)
    @test Float64(green(lifted[1, 1])) ≈ 0.1 atol = 0.01
    grounded = twilight(fill(RGB{N0f8}(0, 0, 0), 4, 4); shadow = 0.0)
    @test grounded[1, 1] == RGB{N0f8}(0, 0, 0)
end

@testitem "twilight: invalid parameters are rejected" begin
    using ImageCore
    img = fill(RGB{N0f8}(0.5, 0.5, 0.5), 4, 4)
    @test_throws ArgumentError twilight(img; value = 0)
    @test_throws ArgumentError twilight(img; gamma = 0)
    @test_throws ArgumentError twilight(img; shadow = 1.0)
    @test_throws ArgumentError twilight(img; shadow = -0.1)
end

@testitem "Appearance: the enum exposes LIGHT and DARK" begin
    @test Appearance.LIGHT isa Appearance.T
    @test Appearance.DARK isa Appearance.T
    @test Appearance.LIGHT != Appearance.DARK
end

@testitem "apply: the light variant leaves brightness alone" begin
    using ImageCore, Random
    img = rand(MersenneTwister(5), RGB{N0f8}, 32, 32)
    e = Oil(radius = 2)
    @test apply(e, img; appearance = Appearance.LIGHT) == apply(e, img)
end

@testitem "apply: the dark variant is darker than the light one" begin
    using ImageCore, Random, Statistics
    img = rand(MersenneTwister(6), RGB{N0f8}, 32, 32)
    e = Oil(radius = 2)
    mean_v(x) = mean(Float64.(channelview(x)))
    @test mean_v(apply(e, img; appearance = Appearance.DARK)) <
          mean_v(apply(e, img; appearance = Appearance.LIGHT))
end
