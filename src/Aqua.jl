@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), "```julia" => "```jldoctest")
end ->
module Aqua

using Base: PkgId
using Test

include("ambiguities.jl")
include("unbound_args.jl")
include("exports.jl")

"""
    test_all(testtarget::Module)

Run following tests in isolated testset:

* [`test_ambiguities`](@ref)
* [`test_unbound_args`](@ref)
* [`test_undefined_exports`](@ref)
"""
function test_all(testtarget::Module)
    @testset "Method ambiguity" begin
        test_ambiguities(testtarget)
    end
    @testset "Unbound type parameters" begin
        test_unbound_args(testtarget)
    end
    @testset "Undefined exports" begin
        test_undefined_exports(testtarget)
    end
end

end # module
