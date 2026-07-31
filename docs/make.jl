using Documenter
using PhotoEffects

makedocs(
    sitename = "PhotoEffects.jl",
    modules = [PhotoEffects],
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Interactive notebooks" => "notebooks.md",
        "API reference" => "reference.md"
    ],
    checkdocs = :exports,
    warnonly = false
)

docs_root = joinpath(@__DIR__, "src")
build_root = joinpath(@__DIR__, "build")
pages = ["index.md", "guide.md", "notebooks.md", "reference.md"]

summary = """
# PhotoEffects.jl

> Turn photographs into LowPoly, Voronoi, oil-painted, posterized, duotone,
> or halftone images with reusable seeding and appearance controls.

- [Documentation](./)
- [Guide](./guide/)
- [Interactive notebooks](./notebooks/)
- [API reference](./reference/)
"""

full = join(
    ("<!-- Source: $(page) -->\n\n" * read(joinpath(docs_root, page), String)
    for page in pages),
    "\n\n"
)

write(joinpath(build_root, "llms.txt"), summary)
write(joinpath(build_root, "llms-full.txt"), full)

if get(ENV, "GITHUB_ACTIONS", "false") == "true"
    deploydocs(
        repo = "github.com/s-celles/PhotoEffects.jl.git",
        push_preview = true
    )
end
