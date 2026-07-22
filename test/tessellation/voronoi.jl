@testitem "Voronoi: size is preserved" begin
    using ImageCore, Random
    img = rand(MersenneTwister(1), RGB{N0f8}, 120, 200)
    @test size(apply(Voronoi(points = 200), img)) == (120, 200)
end

@testitem "Voronoi: the whole image is covered" begin
    using ImageCore
    # Every pixel belongs to the cell of its nearest seed, so coverage is
    # total by construction, with no clipping edge case.
    img = fill(RGB{N0f8}(0.2, 0.4, 0.7), 150, 240)
    @test all(apply(Voronoi(points = 150), img) .== img[1, 1])
end

@testitem "Voronoi: cells are flat" begin
    using ImageCore, Random
    img = rand(MersenneTwister(2), RGB{N0f8}, 100, 100)
    out = apply(Voronoi(points = 120), img)
    @test length(unique(out)) <= 120
end

@testitem "Voronoi: the cell count follows `points`" begin
    using ImageCore, Random
    img = rand(MersenneTwister(6), RGB{N0f8}, 128, 128)
    # Each seed owns at least its own pixel, so there are as many non-empty
    # cells as seeds, up to colour collisions.
    @test length(unique(apply(Voronoi(points = 300), img))) >
          length(unique(apply(Voronoi(points = 60), img)))
end

@testitem "Voronoi: deterministic for equal seeds" begin
    using ImageCore, Random
    img = rand(MersenneTwister(4), RGB{N0f8}, 96, 96)
    e = Voronoi(points = 150)
    @test apply(e, img) == apply(e, img)
end

@testitem "Voronoi: differs from low-poly on identical seeds" begin
    using ImageCore, Random
    # Same seeds, dual tilings: triangles against polygonal cells.
    img = rand(MersenneTwister(7), RGB{N0f8}, 96, 96)
    @test apply(Voronoi(points = 150, seed = 42), img) !=
          apply(LowPoly(points = 150, seed = 42), img)
end

@testitem "Voronoi: invalid parameters are rejected" begin
    @test_throws ArgumentError Voronoi(points = 0)
    @test_throws ArgumentError Voronoi(detail = -0.5)
end
