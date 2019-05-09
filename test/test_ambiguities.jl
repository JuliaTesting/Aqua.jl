module TestAmbiguities

include("preamble.jl")

using PkgWithAmbiguities

@testset begin
    @info "↓↓↓ Following failures are expected. ↓↓↓"
    results = @testtestset begin
        Aqua.test_ambiguities(PkgWithAmbiguities)
    end
    @info "↑↑↑ Above failures are expected. ↑↑↑"
    @test length(results) == 1
    @test results[1] isa Test.Fail

    # It works with other tests:
    Aqua.test_unbound_args(PkgWithAmbiguities)
    Aqua.test_undefined_exports(PkgWithAmbiguities)
end

end  # module
