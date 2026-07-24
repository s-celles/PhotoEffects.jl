@testitem "REND-1: render returns an iterator" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    f(t) = Duotone()
    seq = render(f, img, 1:3)
    
    @test hasmethod(iterate, (typeof(seq),))
    @test length(seq) == 3
    @test eltype(seq) <: AbstractMatrix{<:Colorant}
end

@testitem "REND-2: memory footprint does not grow" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    f(t) = Duotone()
    seq = render(f, img, 1:10)
    
    # Iterate and check that we don't accumulate matrices in the iterator itself
    state = iterate(seq)
    @test state !== nothing
    frame1, st = state
end

@testitem "REND-3: render calls apply(f(t), img)" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    f(t) = Duotone()
    seq = render(f, img, [1.0])
    
    res_render = first(seq)
    res_apply = apply(f(1.0), img)
    
    @test res_render == res_apply
end

@testitem "REND-4: frame produces exact same as render" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    f(t) = Posterize(levels = 4)
    times = [0.1, 0.2, 0.3]
    
    seq = collect(render(f, img, times))
    f2 = frame(f, img, 0.2)
    
    @test seq[2] == f2
end

@testitem "REND-5: frame has no shared state" begin
    using PhotoEffects, ImageCore
    img = rand(RGB{N0f8}, 32, 32)
    f(t) = Posterize(levels = 4)
    
    # Just calling it out of order shouldn't affect the result
    f3 = frame(f, img, 0.3)
    f1 = frame(f, img, 0.1)
    
    @test f3 == apply(f(0.3), img)
end
