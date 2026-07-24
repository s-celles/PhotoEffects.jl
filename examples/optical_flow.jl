using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path="..")
Pkg.add(["ImageCore", "ImageFiltering", "FileIO", "ImageIO", "ImageMagick", "TestImages", "StaticArrays", "Colors", "Interpolations"])

using PhotoEffects
using ImageCore, ImageFiltering, FileIO, TestImages
using StaticArrays, Interpolations, Colors

function compute_flow_field(img)
    # Convert to grayscale for gradient calculation
    img_gray = Float32.(Gray.(img))
    
    # Compute gradients (Sobel filter)
    gy, gx = imgradients(img_gray, KernelFactors.sobel)
    
    # The perpendicular vector (vx, vy) points along the isocontours
    vx = -gy
    vy = gx
    
    h, w = size(img)
    # Interpolation for fluid subpixel access (with Flat boundary conditions)
    interp_vx = linear_interpolation((1:h, 1:w), vx, extrapolation_bc=Flat())
    interp_vy = linear_interpolation((1:h, 1:w), vy, extrapolation_bc=Flat())
    
    return interp_vx, interp_vy
end

function advect_points(pts, interp_vx, interp_vy, w, h, dt)
    next_pts = SVector{2, Float64}[]
    for p in pts
        x, y = p[1], p[2]
        
        # Interpolations.jl normally uses (row, column) indexing -> (y, x)
        v_x = interp_vx(y, x)
        v_y = interp_vy(y, x)
        
        # Integration (explicit Euler)
        x_new = clamp(x + v_x * dt, 1.0, Float64(w))
        y_new = clamp(y + v_y * dt, 1.0, Float64(h))
        
        push!(next_pts, SVector(x_new, y_new))
    end
    return next_pts
end

function generate_flow_animation()
    println("Loading test image (landscape)...")
    img = testimage("lake")
    h, w = size(img)
    
    println("Computing flow field...")
    interp_vx, interp_vy = compute_flow_field(img)
    
    println("Generating initial seeding...")
    # Pseudo-random seeding guided by contours to start
    initial_seeding = sow(Scatter(points = 2500, seed = 42), img)
    pts = initial_seeding.points
    
    # Animation parameters
    N_frames = 50
    half_N = N_frames ÷ 2
    
    println("Precomputing perfectly looped trajectory...")
    forward_trajectory = [pts]
    curr = pts
    for i in 1:half_N
        # ease-in / ease-out via a sinusoidal velocity
        step_dt = 30.0 * sin(π * (i - 0.5) / half_N)
        curr = advect_points(curr, interp_vx, interp_vy, w, h, step_dt)
        push!(forward_trajectory, curr)
    end
    
    # Mirror the trajectory to create a perfect seamless loop
    # e.g.: 1, 2, ..., 26, 25, ..., 2 (total = 50 frames)
    full_trajectory = vcat(forward_trajectory, forward_trajectory[end-1:-1:2])
    
    println("Rendering \$N_frames frames...")
    
    f = function(t)
        # Lazy rendering using the precomputed trajectory
        return Voronoi(Given(full_trajectory[t]))
    end
    
    frames = render(f, img, 1:N_frames)
    
    println("Saving animation to optical_flow_voronoi.gif...")
    anim = collect(frames)
    save("optical_flow_voronoi.gif", cat(anim..., dims=3))
    println("Done!")
end

generate_flow_animation()
