module TestUnboundArgs

include("preamble.jl")

using PkgUnboundArgs

@testset begin
    results = @testtestset begin
        Aqua.test_unbound_args(PkgUnboundArgs)
    end
    @test length(results) == 1
    @test results[1] isa Test.Fail

    # It works with other tests:
    Aqua.test_ambiguities(PkgUnboundArgs)
    Aqua.test_undefined_exports(PkgUnboundArgs)
end

end  # module
