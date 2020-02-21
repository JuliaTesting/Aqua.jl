module Aqua

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), "```julia" => "```jldoctest")
end Aqua

using Base: PkgId
using Pkg: TOML
using Test

include("utils.jl")
include("ambiguities.jl")
include("unbound_args.jl")
include("exports.jl")
include("project_extras.jl")

"""
    test_all(testtarget::Module)

Run following tests in isolated testset:

* [`test_ambiguities([testtarget, Base])`](@ref test_ambiguities)
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
        test_ambiguities([testtarget, Base]; ambiguities...)
    end
    @testset "Unbound type parameters" begin
        test_unbound_args(testtarget)
    end
    @testset "Undefined exports" begin
        test_undefined_exports(testtarget)
    end
end

end # module
