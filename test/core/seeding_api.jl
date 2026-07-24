@testitem "SEED-1: expose Seeding, Scatter, Given, sow" begin
    using PhotoEffects
    @test Seeding isa Type
    @test Scatter <: Seeding
    @test Given <: Seeding
    @test isdefined(PhotoEffects, :sow)
end

@testitem "SEED-2: sow gives identical points for identical inputs" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    s1 = Scatter(points = 100, detail = 1.0, background = 5.0, seed = 42)
    s2 = Scatter(points = 100, detail = 1.0, background = 5.0, seed = 42)
    g1 = sow(s1, img)
    g2 = sow(s2, img)
    @test g1.points == g2.points
end

@testitem "SEED-3: sow on Given is identity" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    pts = [PhotoEffects.SVector(1.0, 1.0)]
    g1 = Given(pts)
    g2 = sow(g1, img)
    @test g1 === g2
end

@testitem "SEED-4, COMP-1, COMP-2: Scatter reproduces old draw" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    
    old_effect = Voronoi(points = 100, seed = 42)
    new_effect = Voronoi(Scatter(points = 100, detail = 1.4, background = 5.0, seed = 42))
    
    out_old = apply(old_effect, img)
    out_new = apply(new_effect, img)
    
    @test out_old == out_new
end

@testitem "SEED-5: sow is pure" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    img_copy = copy(img)
    s = Scatter(points = 100, detail = 1.0, background = 5.0, seed = 42)
    sow(s, img)
    @test img == img_copy
end

@testitem "SEED-6: apply with Given consumes no RNG" begin
    using PhotoEffects, ImageCore, Random
    img = rand(RGB{N0f8}, 32, 32)
    pts = [PhotoEffects.SVector(10.0, 10.0), PhotoEffects.SVector(20.0, 20.0), PhotoEffects.SVector(10.0, 20.0), PhotoEffects.SVector(20.0, 10.0)]
    effect = Voronoi(Given(pts))
    
    rng_state = copy(Random.default_rng())
    apply(effect, img)
    @test rng_state == Random.default_rng()
end

@testitem "SEED-7: Given with too few points raises ArgumentError" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    # LowPoly requires >= 3 points
    pts2 = [PhotoEffects.SVector(10.0, 10.0), PhotoEffects.SVector(20.0, 20.0)]
    @test_throws ArgumentError apply(LowPoly(Given(pts2)), img)
    
    # Voronoi requires >= 1 point
    pts0 = PhotoEffects.SVector{2, Float64}[]
    @test_throws ArgumentError apply(Voronoi(Given(pts0)), img)
end

@testitem "REPRO-1, REPRO-2, REPRO-3: immutability and reproducibility" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    pts = [PhotoEffects.SVector(10.0, 10.0), PhotoEffects.SVector(20.0, 20.0), PhotoEffects.SVector(10.0, 20.0), PhotoEffects.SVector(20.0, 10.0)]
    
    e1 = LowPoly(Given(pts))
    e2 = LowPoly(Given(copy(pts)))
    
    @test hash(e1) == hash(e2)
    @test isequal(e1, e2)
    @test apply(e1, img) == apply(e2, img)
end
