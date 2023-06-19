module TestAmbiguities

include("preamble.jl")

using PkgWithAmbiguities

@testset begin
    @static if VERSION >= v"1.3-"
        results = @testtestset begin
            @info "↓↓↓ Following failures are expected. ↓↓↓"
            Aqua.test_ambiguities(PkgWithAmbiguities)

            # exclude just anything irrelevant, see #49
            Aqua.test_ambiguities(PkgWithAmbiguities; exclude = [convert])

            Aqua.test_ambiguities(
                PkgWithAmbiguities;
                exclude = [PkgWithAmbiguities.f, PkgWithAmbiguities.AbstractType],
            )
            @info "↑↑↑ Above failures are expected. ↑↑↑" # move above once broken test fixed
        end
        @test length(results) == 3
        @test results[1] isa Test.Fail
        @test results[2] isa Test.Fail
        @test_broken results[3] isa Test.Pass
    else
        results = @testtestset begin
            @info "↓↓↓ Following failures are expected. ↓↓↓"
            Aqua.test_ambiguities(PkgWithAmbiguities)
            @info "↑↑↑ Above failures are expected. ↑↑↑"
        end
        @test length(results) == 1
        @test results[1] isa Test.Fail
    end

    # It works with other tests:
    Aqua.test_unbound_args(PkgWithAmbiguities)
    Aqua.test_undefined_exports(PkgWithAmbiguities)
end

end  # module
