#!/usr/bin/env julia
#
# Headless evaluation of the documentation notebooks.
#
# KaimonSlate's `slate` CLI only opens a hub and a browser, but the engine
# underneath is drivable from a script: parse the notebook, build its
# dependency graph, evaluate every stale cell. `@bind` controls resolve to
# their default value, so the whole page is exercised without a UI.
#
# Run it from the package root:
#
#     julia --project=docs docs/validate.jl
#
# KaimonSlate is not in the General registry, so the environment needs it
# added by URL first — see docs/README.md.
#
# Exit code is the number of failed cells, so CI can gate on it.

using KaimonSlate
const KS = KaimonSlate

const NOTEBOOKS = joinpath(@__DIR__, "notebooks")

"""
Evaluate one notebook and report per-cell state. Returns the failure count.
"""
function check(path::AbstractString)
    println("── ", basename(path))
    report = KS.parse_report(read(path, String))
    KS.build_dependencies!(report)
    KS.eval_stale!(report)

    failed = filter(c -> c.state == KS.ERRORED, report.cells)
    for c in failed
        println("  ERROR in cell `", c.id, "`")
        println("    ", first(string(c.output), 500))
    end
    println("  ", length(report.cells), " cells, ", length(failed), " failed")
    return length(failed)
end

notebooks = sort(filter(endswith(".jl"), readdir(NOTEBOOKS; join = true)))
isempty(notebooks) && error("no notebook found in $NOTEBOOKS")

total = sum(check, notebooks)
println(total == 0 ? "\nall notebooks evaluate cleanly" : "\n$total cell(s) failed")
exit(total)
