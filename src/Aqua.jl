module Aqua

using Test

include("ambiguities.jl")
include("exports.jl")

function test_unbound_args(m::Module)
    @test detect_unbound_args(m) == []
end

"""
    autoqa(testtarget::Module)
"""
function autoqa(testtarget::Module)
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
