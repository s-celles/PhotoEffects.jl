@testitem "Border paints an exact clipped inner mat" begin
    using ImageCore

    image = fill(RGB{N0f8}(0.2, 0.4, 0.6), 20, 30)
    mat = RGB{N0f8}(0.95, 0.9, 0.8)
    result = apply(Border(width = 3, color = mat), image)

    @test all(result[1:3, :] .== mat)
    @test all(result[(end - 2):end, :] .== mat)
    @test all(result[:, 1:3] .== mat)
    @test all(result[:, (end - 2):end] .== mat)
    @test result[4, 4] == image[4, 4]
    @test count(==(mat), result) == length(image) - 14 * 24
end

@testitem "Border supports identity and oversized mats" begin
    using ImageCore, Random

    image = rand(MersenneTwister(4), RGB{N0f8}, 8, 10)
    @test apply(Border(width = 0), image) == image
    full = Border(width = 20, color = RGB(0.9, 0.8, 0.7))
    @test all(apply(full, image) .== full.color)
end

@testitem "Border validates width and preserves alpha" begin
    using ImageCore

    image = fill(RGBA{N0f8}(0.2, 0.4, 0.6, 0.35), 20, 24)
    result = apply(Border(width = 2), image)

    @test eltype(result) == RGBA{N0f8}
    @test all(alpha.(result) .== alpha(image[1]))
    @test_throws ArgumentError Border(width = -1)
end
