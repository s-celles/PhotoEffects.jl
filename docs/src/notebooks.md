# Interactive notebooks

The published manual is built with Documenter. Interactive exploration lives
separately in `docs/notebooks/`, using KaimonSlate.

Start the gallery from the documentation environment:

```sh
julia --project=docs -e 'using KaimonSlate; KaimonSlate.serve_notebook("docs/notebooks/index.jl")'
```

The notebook can be validated without opening a browser:

```sh
julia --project=docs docs/validate.jl
```

CI performs both operations that make sense without a GUI: it builds the
Documenter site and evaluates every notebook cell headlessly.
