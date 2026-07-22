# Documentation

The documentation is a [KaimonSlate](https://github.com/kahliburke/KaimonSlate.jl)
notebook: a reactive notebook whose cells recompute when you move a control,
stored as a plain `.jl` file so git reads the same source you edit.

That choice buys the one thing a static site cannot give — you can point it at
**your own photograph** and tune every effect live, without the package ever
having to run in a browser.

| File | Role |
|---|---|
| `notebooks/index.jl` | The gallery: every effect, with live controls. |
| `validate.jl` | Headless evaluation of every notebook, for CI. |
| `Project.toml` | The notebook environment. |

## Running it

KaimonSlate is **not in the General registry** yet, so it installs by URL:

```julia
using Pkg
Pkg.add(url = "https://github.com/kahliburke/KaimonSlate.jl")
```

That puts a `slate` shim in `~/.julia/bin` (make sure it is on your `PATH`).

Then start the hub **from this environment**, not through the bare shim:

```sh
julia --project=docs -e 'using KaimonSlate; KaimonSlate.serve_notebook("docs/notebooks/index.jl")'
```

The hub opens the notebook in your browser. Move the sliders; only the cells
downstream of a control recompute.

> ### Why not just `slate docs/notebooks/index.jl`
>
> Because it fails, with `Package PhotoEffects not found in current path`.
>
> A notebook gets a **gate worker** — carrying the enclosing project's
> environment — only when Kaimon's gate is available. Without it the notebook
> evaluates **in-process**, inside the hub's own environment. The bare `slate`
> shim starts that hub with no `--project`, so cells run in the default
> `v1.12` environment and never see `docs/Project.toml`, even though
> KaimonSlate resolves the enclosing project correctly.
>
> Launching through `--project=docs` puts the hub itself in the right
> environment, so in-process evaluation lands where it should. Getting
> Kaimon's gate running is the other fix, and the one the design intends.
>
> Note that the packages panel's **Add** buttons will not rescue this:
> they run `Pkg.add`, and `PhotoEffects` is not registered. It resolves
> through the `path = ".."` entry in `docs/Manifest.toml`, which only a
> `Pkg.develop` — or the launch above — will honour.

## Publishing

KaimonSlate has a built-in publishing manager with a GitHub Pages target, and
exports a self-contained HTML file.

One caveat worth knowing before relying on it: in a **static export**, `@bind`
widgets become a *frozen parameters strip*. The published page shows the
outputs as rendered at build time — it cannot call back into Julia. Live
tuning is a local-session feature.

To keep real interactivity on the published page, a cell can emit an HTML/JS
widget through the *frontend extensions* mechanism, whose `<script>` runs both
live and in a static export. Pre-render a parameter sweep from Julia, let the
script swap the images client-side. That is not wired up yet.

## Checking the notebooks headlessly

The `slate` CLI only opens a hub and a browser, but the engine underneath is
drivable from a script — parse the notebook, build its dependency graph,
evaluate every stale cell:

```sh
julia --project=docs docs/validate.jl
```

`@bind` controls resolve to their default value, so the whole page is
exercised without a UI. The exit code is the number of failed cells, so CI can
gate on it directly.

This is worth running after any change to the package: a notebook is the one
piece of documentation that can break silently when an effect's constructor
changes, since nothing else compiles it.

> `ImageShow` is a dependency for a reason. Without it, `Colors` renders large
> images as reduced swatches — the notebook still evaluates cleanly, but every
> picture on the page comes out useless. The headless run surfaces it as a
> warning; nothing else would.

## Status

Every notebook evaluates cleanly (24 cells, 0 failures). What remains
unverified is the **publishing** chain — export to a static site and deploy to
Pages have not been exercised, and there is no CI wired up yet.

See [`upstream-bugs.md`](../upstream-bugs.md) for the world-age warnings
KaimonSlate emits under Julia 1.12. They are harmless today but Julia states
they will become errors.
