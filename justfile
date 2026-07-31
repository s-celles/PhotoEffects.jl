set shell := ["bash", "-cu"]

julia := env_var_or_default("JULIA", "julia")

default:
    @just --list

instantiate:
    {{julia}} --project=. -e 'using Pkg; Pkg.instantiate()'

test:
    {{julia}} --project=. -e 'using Pkg; Pkg.test(; allow_reresolve=false)'

format:
    {{julia}} --startup-file=no -e 'using Pkg; Pkg.activate(; temp=true); Pkg.add(name="JuliaFormatter", version="1"); using JuliaFormatter; format(".", verbose=true)'

format-check:
    {{julia}} --startup-file=no -e 'using Pkg; Pkg.activate(; temp=true); Pkg.add(name="JuliaFormatter", version="1"); using JuliaFormatter; format(".", verbose=true) || exit(1)'

docs-instantiate:
    {{julia}} --project=docs -e 'using Pkg; ks=get(ENV, "KAIMONSLATE_PATH", joinpath(homedir(), ".julia", "dev", "KaimonSlate")); Pkg.develop([PackageSpec(path=joinpath(ks, "lib", "SlateExtensionsBase")), PackageSpec(path=ks), PackageSpec(path=pwd())]); Pkg.instantiate()'

docs: docs-instantiate
    {{julia}} --project=docs docs/make.jl
    {{julia}} --project=docs docs/validate.jl

quality: format-check test

check: quality docs
