@testitem "VoronoiStained: joints separate cells" begin
    using ImageCore, Random

    img = rand(MersenneTwister(11), RGB{N0f8}, 80, 120)
    joint = RGB{N0f8}(0.02, 0.03, 0.04)
    plain = apply(Voronoi(points = 80, seed = 7), img)
    stained = apply(
        VoronoiStained(points = 80, seed = 7,
            joint = 2, joint_color = joint),
        img)

    @test size(stained) == size(img)
    @test count(==(joint), stained) > 0
    @test stained != plain
end

@testitem "VoronoiStained: invalid joints are rejected" begin
    @test_throws ArgumentError VoronoiStained(joint = -1)
end

@testitem "VoronoiLloyd: relaxation regularises cell areas" begin
    using ImageCore
    using Statistics: std

    img = fill(RGB{N0f8}(0.4, 0.6, 0.8), 100, 140)
    initial = PhotoEffects._voronoi_cell_counts(
        VoronoiLloyd(points = 80, iterations = 0, seed = 9), img)
    relaxed = PhotoEffects._voronoi_cell_counts(
        VoronoiLloyd(points = 80, iterations = 4, seed = 9), img)

    @test size(apply(VoronoiLloyd(points = 80, iterations = 2), img)) ==
          size(img)
    @test std(relaxed) < std(initial)
end

@testitem "VoronoiLloyd: invalid iterations are rejected" begin
    @test_throws ArgumentError VoronoiLloyd(iterations = -1)
end
