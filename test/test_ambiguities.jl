module TestAmbiguities

include("preamble.jl")

using PkgWithAmbiguities

@testset begin
    function check_testcase(exclude, num_ambiguities::Int; broken::Bool = false)
        pkgids = Aqua.aspkgids([PkgWithAmbiguities, Core]) # include Core to find constructor ambiguities
        num_ambiguities_, strout, strerr = Aqua._find_ambiguities(pkgids; exclude = exclude)
        if broken
            @test_broken num_ambiguities_ == num_ambiguities
        else
            @test num_ambiguities_ == num_ambiguities
        end
        @test isempty(strerr)
    end

    total = 9


    check_testcase([], total)

    # exclude just anything irrelevant, see #49
    check_testcase([convert], total)

    # exclude function
    check_testcase([PkgWithAmbiguities.f], total - 1)

    # exclude callables and constructors
    check_testcase([PkgWithAmbiguities.SingletonType], total - 2 - 1)
    check_testcase([PkgWithAmbiguities.ConcreteType], total - 3 - 1)

    # exclude abstract supertype without callables and constructors
    check_testcase([PkgWithAmbiguities.AbstractType], total)

    # for ambiguities between abstract and concrete type callables, only one needs to be excluded
    check_testcase([PkgWithAmbiguities.AbstractParameterizedType], total - 1)
    check_testcase([PkgWithAmbiguities.ConcreteParameterizedType], total - 1)

    # exclude everything
    check_testcase(
        [
            PkgWithAmbiguities.f,
            PkgWithAmbiguities.SingletonType,
            PkgWithAmbiguities.ConcreteType,
            PkgWithAmbiguities.ConcreteParameterizedType,
        ],
        0,
    )

    # It works with other tests:
    Aqua.test_unbound_args(PkgWithAmbiguities)
    Aqua.test_undefined_exports(PkgWithAmbiguities)
end

end  # module
