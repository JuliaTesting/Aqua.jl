module TestStaleDeps

include("preamble.jl")
using Aqua: PkgId, UUID, _analyze_stale_deps_2, ispass, ⊜

@testset "_analyze_stale_deps_2" begin
    pkg = PkgId(UUID(42), "TargetPkg")

    dep1 = PkgId(UUID(1), "Dep1")
    dep2 = PkgId(UUID(2), "Dep2")
    dep3 = PkgId(UUID(3), "Dep3")

    @testset "pass" begin
        @test _analyze_stale_deps_2(;
            pkg = pkg,
            deps = PkgId[],
            loaded_uuids = UUID[],
            ignore = Symbol[],
        ) ⊜ true
        @test _analyze_stale_deps_2(;
            pkg = pkg,
            deps = PkgId[dep1],
            loaded_uuids = UUID[dep1.uuid, dep2.uuid, dep3.uuid],
            ignore = Symbol[],
        ) ⊜ true
        @test _analyze_stale_deps_2(;
            pkg = pkg,
            deps = PkgId[dep1],
            loaded_uuids = UUID[dep2.uuid, dep3.uuid],
            ignore = Symbol[:Dep1],
        ) ⊜ true
    end
    @testset "failure" begin
        @test _analyze_stale_deps_2(;
            pkg = pkg,
            deps = PkgId[dep1],
            loaded_uuids = UUID[],
            ignore = Symbol[],
        ) ⊜ false
        @test _analyze_stale_deps_2(;
            pkg = pkg,
            deps = PkgId[dep1],
            loaded_uuids = UUID[dep2.uuid, dep3.uuid],
            ignore = Symbol[],
        ) ⊜ false
        @test _analyze_stale_deps_2(;
            pkg = pkg,
            deps = PkgId[dep1, dep2],
            loaded_uuids = UUID[dep3.uuid],
            ignore = Symbol[:Dep1],
        ) ⊜ false
    end
end

with_sample_pkgs() do
    @testset "PkgWithoutProject" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithoutProject"]
        results = Aqua.analyze_stale_deps(pkg)
        @test length(results) == 1
        r, = results
        @test !ispass(r)
        @test r ⊜ false
        msg = sprint(show, "text/plain", r)
        @test occursin("Project.toml file at project directory does not exist", msg)
    end
end

end  # module
