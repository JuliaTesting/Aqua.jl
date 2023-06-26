module TestAmbiguities

include("preamble.jl")

using PkgWithAmbiguities

@testset begin
    @static if VERSION >= v"1.3-"
        num_ambiguities, strout, strerr =
            Aqua._find_ambiguities(Aqua.aspkgids(PkgWithAmbiguities))
        @test num_ambiguities == 2
        @test isempty(strerr)

        # exclude just anything irrelevant, see #49
        num_ambiguities, strout, strerr =
            Aqua._find_ambiguities(Aqua.aspkgids(PkgWithAmbiguities); exclude = [convert])
        @test num_ambiguities == 2
        @test isempty(strerr)

        num_ambiguities, strout, strerr = Aqua._find_ambiguities(
            Aqua.aspkgids(PkgWithAmbiguities);
            exclude = [PkgWithAmbiguities.f, PkgWithAmbiguities.AbstractType],
        )
        @test_broken num_ambiguities == 0
        @test isempty(strerr)
    else
        num_ambiguities, strout, strerr =
            Aqua._find_ambiguities(Aqua.aspkgids(PkgWithAmbiguities))
        @test num_ambiguities == 1
        @test isempty(strerr)
    end

    # It works with other tests:
    Aqua.test_unbound_args(PkgWithAmbiguities)
    Aqua.test_undefined_exports(PkgWithAmbiguities)
end

end  # module
