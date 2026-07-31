# PhotoEffects.jl

PhotoEffects turns photographs into stylised images through immutable,
composable effect values.

```@docs
PhotoEffects
```

```julia
using FileIO, PhotoEffects

img = load("photo.jpg")
out = apply(Oil(radius = 9, passes = 2), fit_cover(img, 1920, 1080))
save("painting.png", out)
```

The package separates effects, point seeding, framing, and appearance so the
same geometry can be reused across renders and animations.

```@contents
Pages = ["guide.md", "notebooks.md", "reference.md"]
Depth = 2
```

Development assistance is disclosed as: Assisted-by: AI.
