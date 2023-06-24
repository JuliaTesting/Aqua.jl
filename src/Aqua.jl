module Aqua

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end Aqua

using Base: PkgId, UUID
using Pkg: Pkg, TOML
using Test

try
    findnext('a', "a", 1)
catch
    import Compat
end

include("pkg/Versions.jl")
using .Versions: VersionSpec, semver_spec

include("utils.jl")
include("ambiguities.jl")
include("unbound_args.jl")
include("exports.jl")
include("project_extras.jl")
include("stale_deps.jl")
include("deps_compat.jl")
include("project_toml_formatting.jl")
include("piracy.jl")

"""
    test_all(testtarget::Module)

Run following tests in isolated testset:

* [`test_ambiguities([testtarget, Base, Core])`](@ref test_ambiguities)
* [`test_unbound_args(testtarget)`](@ref test_unbound_args)
* [`test_undefined_exports(testtarget)`](@ref test_undefined_exports)
* [`test_project_extras(testtarget)`](@ref test_project_extras)
* [`test_stale_deps(testtarget)`](@ref test_stale_deps)
* [`test_deps_compat(testtarget)`](@ref test_deps_compat)
* [`test_project_toml_formatting(testtarget)`](@ref test_project_toml_formatting)
* [`test_piracy(testtarget)`](@ref test_piracy)

!!! compat "Aqua.jl 0.5"

    Since Aqua.jl 0.5:

    * `test_all` runs [`test_ambiguities`](@ref) with `Core`.  This
       means method ambiguities of constructors can now be detected.
       In Aqua.jl 0.4, `test_ambiguities` was invoked with
       `[testtarget, Base]`.

    * `test_all` runs [`test_stale_deps`](@ref).  In Aqua.jl 0.4, this
      check was opt-in.

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
- `project_toml_formatting = true`
- `piracy = true`
"""
function test_all(
    testtarget::Module;
    ambiguities = true,
    unbound_args = true,
    undefined_exports = true,
    project_extras = true,
    stale_deps = true,
    deps_compat = true,
    project_toml_formatting = true,
    piracy = true,
)
    @testset "Method ambiguity" begin
        if ambiguities !== false
            if v"1.6.0-DEV.816" <= VERSION < v"1.6.0-DEV.875"
                # Maybe remove this branch?
                @warn "Ignoring ambiguities from `Base` to workaround JuliaLang/julia#36962"
                test_ambiguities([testtarget]; askwargs(ambiguities)...)
            else
                test_ambiguities([testtarget, Base, Core]; askwargs(ambiguities)...)
            end
        end
    end
    @testset "Unbound type parameters" begin
        if unbound_args !== false
            test_unbound_args(testtarget; askwargs(unbound_args)...)
        end
    end
    @testset "Undefined exports" begin
        if undefined_exports !== false
            test_undefined_exports(testtarget; askwargs(undefined_exports)...)
        end
    end
    @testset "Compare Project.toml and test/Project.toml" begin
        if project_extras !== false
            test_project_extras(testtarget; askwargs(project_extras)...)
        end
    end
    @testset "Stale dependencies" begin
        if stale_deps !== false
            test_stale_deps(testtarget; askwargs(stale_deps)...)
        end
    end
    @testset "Compat bounds" begin
        if deps_compat !== false
            test_deps_compat(testtarget; askwargs(deps_compat)...)
        end
    end
    @testset "Project.toml formatting" begin
        if project_toml_formatting !== false
            test_project_toml_formatting(testtarget; askwargs(project_toml_formatting)...)
        end
    end
    @testset "Piracy" begin
        if piracy !== false
            test_piracy(testtarget; askwargs(piracy)...)
        end
    end
end

end # module
