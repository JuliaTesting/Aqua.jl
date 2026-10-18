module TestAmbiguities

include("preamble.jl")

@testset begin
    using PkgWithAmbiguities

    using PkgWithAmbiguities:
        num_ambs_f,
        num_ambs_g,
        num_ambs_SingletonType,
        num_ambs_ConcreteType,
        num_ambs_ParameterizedType
    total =
        num_ambs_f +
        num_ambs_g +
        num_ambs_SingletonType +
        num_ambs_ConcreteType +
        num_ambs_ParameterizedType

    function check_testcase(exclude, num_ambiguities::Int; broken::Bool = false)
        pkgids = Aqua.aspkgids([PkgWithAmbiguities, Core]) # include Core to find constructor ambiguities
        num_ambiguities_, strout, strerr = Aqua._find_ambiguities(pkgids; exclude = exclude)
        if broken
            @test_broken num_ambiguities_ == num_ambiguities
        else
            if num_ambiguities_ != num_ambiguities
                @show exclude
                println(strout)
                println(strerr)
            end
            @test num_ambiguities_ == num_ambiguities
        end
    end

    check_testcase([], total)

    # exclude just anything irrelevant, see #49
    check_testcase([convert], total)

    # exclude function
    check_testcase([PkgWithAmbiguities.f], total - num_ambs_f)

    # exclude function and kwsorter
    check_testcase([PkgWithAmbiguities.g], total - num_ambs_g)

    # exclude callables and constructors
    check_testcase([PkgWithAmbiguities.SingletonType], total - num_ambs_SingletonType)
    check_testcase([PkgWithAmbiguities.ConcreteType], total - num_ambs_ConcreteType)

    # exclude abstract supertype without callables and constructors
    check_testcase([PkgWithAmbiguities.AbstractType], total)

    # for ambiguities between abstract and concrete type callables, only one needs to be excluded
    check_testcase(
        [PkgWithAmbiguities.AbstractParameterizedType],
        total - num_ambs_ParameterizedType,
    )
    check_testcase(
        [PkgWithAmbiguities.ConcreteParameterizedType],
        total - num_ambs_ParameterizedType,
    )

    # exclude everything
    check_testcase(
        [
            PkgWithAmbiguities.f,
            PkgWithAmbiguities.g,
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
