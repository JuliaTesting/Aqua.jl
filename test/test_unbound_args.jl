module TestUnboundArgs

include("preamble.jl")

using PkgUnboundArgs

@testset begin
    println("### Expected output START ###")
    results = @testtestset begin
        Aqua.test_unbound_args(PkgUnboundArgs)
    end
    println("### Expected output END ###")
    @test length(results) == 1
    @test results[1] isa Test.Fail

    Aqua.test_unbound_args(
        PkgUnboundArgs,
        ignore = [
            (PkgUnboundArgs.M25341._totuple, Type{Tuple{Vararg{E}}} where {E}, Any, Vararg),
            (PkgUnboundArgs.Issue86.f, NTuple),
        ],
    )

    # It works with other tests:
    Aqua.test_ambiguities(PkgUnboundArgs)
    Aqua.test_undefined_exports(PkgUnboundArgs)
end

end  # module
