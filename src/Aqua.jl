module Aqua

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), "```julia" => "```jldoctest")
end Aqua

using Base: PkgId, UUID
using Pkg: Pkg, TOML
using Test

include("utils.jl")
include("ambiguities.jl")
include("unbound_args.jl")
include("exports.jl")
include("project_extras.jl")
include("stale_deps.jl")
include("deps_compat.jl")

"""
    test_all(testtarget::Module)

Run following tests in isolated testset:

* [`test_ambiguities([testtarget, Base])`](@ref test_ambiguities)
  (Note: To ignore ambiguities from `Base` due to
  [JuliaLang/julia#36962](https://github.com/JuliaLang/julia/pull/36962),
  `test_ambiguities(testtarget)` is called instead for Julia nightly
  later than 1.6.0-DEV.816 for now. Depending on how
  JuliaLang/julia#36962 is resolved, this special-casing may be
  removed in later versions of Aqua.jl.)
* [`test_unbound_args(testtarget)`](@ref test_unbound_args)
* [`test_undefined_exports(testtarget)`](@ref test_undefined_exports)

# Keyword Arguments
- `ambiguities`: Keyword arguments passed to [`test_ambiguities`](@ref).
"""
function test_all(
    testtarget::Module;
    ambiguities = (),
    # unbound_args = (),
    # undefined_exports = (),
)
    @testset "Method ambiguity" begin
        if VERSION >= v"1.6.0-DEV.816"
            @warn "Ignoring ambiguities from `Base` to workaround JuliaLang/julia#36962"
            test_ambiguities([testtarget]; ambiguities...)
        else
            test_ambiguities([testtarget, Base]; ambiguities...)
        end
    end
    @testset "Unbound type parameters" begin
        test_unbound_args(testtarget)
    end
    @testset "Undefined exports" begin
        test_undefined_exports(testtarget)
    end
end

end # module
