module Aqua

using Base: Docs, PkgId, UUID
using Pkg: Pkg, TOML, PackageSpec
using Pkg.Types: VersionSpec, semver_spec
using Test


include("utils.jl")
include("ambiguities.jl")
include("unbound_args.jl")
include("exports.jl")
include("project_extras.jl")
include("stale_deps.jl")
include("deps_compat.jl")
include("piracies.jl")
include("persistent_tasks.jl")
include("undocumented_names.jl")

"""
    test_all(testtarget::Module)

Run the following tests on the module `testtarget`:

* [`test_ambiguities([testtarget])`](@ref test_ambiguities)
* [`test_unbound_args(testtarget)`](@ref test_unbound_args)
* [`test_undefined_exports(testtarget)`](@ref test_undefined_exports)
* [`test_project_extras(testtarget)`](@ref test_project_extras)
* [`test_stale_deps(testtarget)`](@ref test_stale_deps)
* [`test_deps_compat(testtarget)`](@ref test_deps_compat)
* [`test_piracies(testtarget)`](@ref test_piracies)
* [`test_persistent_tasks(testtarget)`](@ref test_persistent_tasks)
* [`test_undocumented_names(testtarget)`](@ref test_undocumented_names)

The keyword argument `\$x` (e.g., `ambiguities`) can be used to
control whether or not to run `test_\$x` (e.g., `test_ambiguities`).
If `test_\$x` supports keyword arguments, a `NamedTuple` can also be
passed to `\$x` to specify the keyword arguments for `test_\$x`.

# Keyword Arguments
- `ambiguities = true`
- `unbound_args = true`
- `undefined_exports = true`
- `project_extras = true`
- `stale_deps = true`
- `deps_compat = true`
- `piracies = true`
- `persistent_tasks = true`
- `undocumented_names = false`
"""
function test_all(
    testtarget::Module;
    ambiguities = true,
    unbound_args = true,
    undefined_exports = true,
    project_extras = true,
    stale_deps = true,
    deps_compat = true,
    piracies = true,
    persistent_tasks = true,
    undocumented_names = false,
)
    # Launch subprocess-based checks together, then record their Test results on
    # this task. Persistent-task setup runs first because it changes Pkg state
    # that the other checks read when launching their subprocesses.
    persistent_tasks_launch = enabled(persistent_tasks) ?
        Threads.@spawn(_launch_persistent_tasks(
            PkgId(testtarget);
            askwargs(persistent_tasks)...,
        )) : nothing
    ambiguities_task = nothing
    stale_deps_task = nothing
    persistent_tasks_task = nothing
    tasks = Task[]
    try
        persistent_tasks_launch === nothing ||
            timedwait(() -> istaskdone(persistent_tasks_launch), Inf)
        ambiguities_task = enabled(ambiguities) ?
            Threads.@spawn(_result_ambiguities(
                aspkgids([testtarget]);
                askwargs(ambiguities)...,
            )) : nothing
        stale_deps_task = enabled(stale_deps) ?
            Threads.@spawn(find_stale_deps(
                aspkgid(testtarget);
                askwargs(stale_deps)...,
            )) : nothing
        persistent_tasks_task = persistent_tasks_launch === nothing ? nothing :
            Threads.@spawn(_await_persistent_tasks(persistent_tasks_launch))
        append!(tasks, filter(!isnothing, [
            ambiguities_task, stale_deps_task, persistent_tasks_task
        ]))
        timedwait(() -> all(istaskdone, tasks), Inf)
    finally
        persistent_tasks_launch === nothing ||
            _stop_persistent_tasks(persistent_tasks_launch)
        timedwait(() -> all(istaskdone, tasks), Inf)
    end

    if enabled(ambiguities)
        @testset "Method ambiguity" begin
            _report_ambiguities(fetch(ambiguities_task))
        end
    end
    if enabled(unbound_args)
        @testset "Unbound type parameters" begin
            test_unbound_args(testtarget; askwargs(unbound_args)...)
        end
    end
    if enabled(undefined_exports)
        @testset "Undefined exports" begin
            test_undefined_exports(testtarget; askwargs(undefined_exports)...)
        end
    end
    if enabled(project_extras)
        @testset "Compare Project.toml and test/Project.toml" begin
            isempty(askwargs(project_extras)) || error("Keyword arguments not supported")
            test_project_extras(testtarget)
        end
    end
    if enabled(stale_deps)
        @testset "Stale dependencies" begin
            stale = fetch(stale_deps_task)
            @test isempty(stale)
        end
    end
    if enabled(deps_compat)
        @testset "Compat bounds" begin
            test_deps_compat(testtarget; askwargs(deps_compat)...)
        end
    end
    if enabled(piracies)
        @testset "Piracy" begin
            test_piracies(testtarget; askwargs(piracies)...)
        end
    end
    if enabled(persistent_tasks)
        @testset "Persistent tasks" begin
            _report_persistent_tasks(fetch(persistent_tasks_task))
        end
    end
    if enabled(undocumented_names)
        @testset "Undocumented names" begin
            isempty(askwargs(undocumented_names)) ||
                error("Keyword arguments not supported")
            test_undocumented_names(testtarget; askwargs(undocumented_names)...)
        end
    end
end

include("precompile.jl")

end # module
