module TestUnusedDeps

include("preamble.jl")
using Base: PkgId, UUID
using Aqua: find_unused_deps_2

@testset "find_unused_deps_2" begin
    pkg = PkgId(UUID(42), "TargetPkg")

    dep1 = PkgId(UUID(1), "Dep1")
    dep2 = PkgId(UUID(2), "Dep2")
    dep3 = PkgId(UUID(3), "Dep3")

    @testset "pass" begin
        result = find_unused_deps_2(;
            deps = PkgId[],
            weakdeps = PkgId[],
            loaded_uuids = UUID[],
            ignore = Symbol[],
        )
        @test isempty(result)

        result = find_unused_deps_2(;
            deps = PkgId[dep1],
            weakdeps = PkgId[],
            loaded_uuids = UUID[dep1.uuid, dep2.uuid, dep3.uuid],
            ignore = Symbol[],
        )
        @test isempty(result)

        result = find_unused_deps_2(;
            deps = PkgId[dep1],
            weakdeps = PkgId[],
            loaded_uuids = UUID[dep2.uuid, dep3.uuid],
            ignore = Symbol[:Dep1],
        )
        @test isempty(result)

        result = find_unused_deps_2(;
            deps = PkgId[dep1],
            weakdeps = PkgId[dep2],
            loaded_uuids = UUID[dep1.uuid],
            ignore = Symbol[],
        )
        @test isempty(result)

        result = find_unused_deps_2(;
            deps = PkgId[dep1, dep2],
            weakdeps = PkgId[dep2],
            loaded_uuids = UUID[dep1.uuid],
            ignore = Symbol[],
        )
        @test isempty(result)

        result = find_unused_deps_2(;
            deps = PkgId[dep1, dep2],
            weakdeps = PkgId[dep2],
            loaded_uuids = UUID[],
            ignore = Symbol[:Dep1],
        )
        @test isempty(result)
    end
    @testset "failure" begin
        result = find_unused_deps_2(;
            deps = PkgId[dep1],
            weakdeps = PkgId[],
            loaded_uuids = UUID[],
            ignore = Symbol[],
        )
        @test length(result) == 1
        @test dep1 in result

        result = find_unused_deps_2(;
            deps = PkgId[dep1],
            weakdeps = PkgId[],
            loaded_uuids = UUID[dep2.uuid, dep3.uuid],
            ignore = Symbol[],
        )
        @test length(result) == 1
        @test dep1 in result

        result = find_unused_deps_2(;
            deps = PkgId[dep1, dep2],
            weakdeps = PkgId[],
            loaded_uuids = UUID[dep3.uuid],
            ignore = Symbol[:Dep1],
        )
        @test length(result) == 1
        @test dep2 in result
    end
end

with_sample_pkgs() do
    @testset "Package without `deps`" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithoutDeps"]
        results = Aqua.find_unused_deps(pkg)
        @test isempty(results)
    end
end

end  # module
