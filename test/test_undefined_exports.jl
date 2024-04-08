module TestUndefinedExports

include("preamble.jl")

using PkgWithUndefinedExports

@testset begin
    @test Aqua.undefined_exports(PkgWithUndefinedExports) ==
          [Symbol("PkgWithUndefinedExports.undefined_name")]
    println("### Expected output START ###")
    results = @testtestset begin
        Aqua.test_undefined_exports(PkgWithUndefinedExports)
    end
    println("### Expected output END ###")
    @test length(results) == 1
    @test results[1] isa Test.Fail

    # It works with other tests:
    Aqua.test_ambiguities(PkgWithUndefinedExports)
    Aqua.test_unbound_args(PkgWithUndefinedExports)
end

end  # module
