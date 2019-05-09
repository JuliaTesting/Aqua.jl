@doc read(joinpath(dirname(@__DIR__), "README.md"), String) ->
module Aqua

using Test

include("ambiguities.jl")
include("exports.jl")

"""
    test_unbound_args(module::Module)

Test that all methods in `module` do not have unbound type parameter.
This test simply calls `Test.detect_unbound_args`.
"""
function test_unbound_args(m::Module)
    @test detect_unbound_args(m; recursive=true) == []
end

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
