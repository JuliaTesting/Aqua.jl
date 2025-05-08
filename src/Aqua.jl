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

Run the following tests:

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
    if ambiguities !== false
        @testset "Method ambiguity" begin
            test_ambiguities([testtarget]; askwargs(ambiguities)...)
        end
    end
    if unbound_args !== false
        @testset "Unbound type parameters" begin
            test_unbound_args(testtarget; askwargs(unbound_args)...)
        end
    end
    if undefined_exports !== false
        @testset "Undefined exports" begin
            test_undefined_exports(testtarget; askwargs(undefined_exports)...)
        end
    end
    if project_extras !== false
        @testset "Compare Project.toml and test/Project.toml" begin
            isempty(askwargs(project_extras)) || error("Keyword arguments not supported")
            test_project_extras(testtarget)
        end
    end
    if stale_deps !== false
        @testset "Stale dependencies" begin
            test_stale_deps(testtarget; askwargs(stale_deps)...)
        end
    end
    if deps_compat !== false
        @testset "Compat bounds" begin
            test_deps_compat(testtarget; askwargs(deps_compat)...)
        end
    end
    if piracies !== false
        @testset "Piracy" begin
            test_piracies(testtarget; askwargs(piracies)...)
        end
    end
    if persistent_tasks !== false
        @testset "Persistent tasks" begin
            test_persistent_tasks(testtarget; askwargs(persistent_tasks)...)
        end
    end
    if undocumented_names !== false
        @testset "Undocumented names" begin
            isempty(askwargs(undocumented_names)) ||
                error("Keyword arguments not supported")
            test_undocumented_names(testtarget; askwargs(undocumented_names)...)
        end
    end
end

end # module
