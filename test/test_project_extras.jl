module TestProjectExtras

include("preamble.jl")
using Aqua: ispass, ⊜
using Base: PkgId, UUID

with_sample_pkgs() do

    results = Dict(zip(
        [p.name for p in AquaTesting.SAMPLE_PKGIDS],
        Aqua.analyze_project_extras(collect(AquaTesting.SAMPLE_PKGIDS)),
    ))
    pkgids = Dict([p.name => p for p in AquaTesting.SAMPLE_PKGIDS])

    @testset "PkgWithIncompatibleTestProject" begin
        r = results["PkgWithIncompatibleTestProject"]
        @test !ispass(r)
        @test r ⊜ false
        msg = sprint(show, "text/plain", r)
        @test occursin("Root and test projects are inconsistent.", msg)
        @test occursin("Test dependencies not in root project", msg)
        @test occursin("Dependencies not in test project", msg)
        @test occursin("Random =", msg)
        @test occursin("REPL =", msg)
        @test !occursin("Test =", msg)
    end

    @testset "PkgWithCompatibleTestProject" begin
        r = results["PkgWithCompatibleTestProject"]
        @test ispass(r)
        Aqua.test_project_extras(pkgids["PkgWithCompatibleTestProject"])
        msg = sprint(show, "text/plain", r)
        @test occursin("Root and test projects are consistent.", msg)
        @test occursin("Root project:", msg)
        @test occursin("Test project:", msg)
    end

    @testset "PkgWithPostJulia12Support" begin
        r = results["PkgWithPostJulia12Support"]
        @test ispass(r)
        Aqua.test_project_extras(pkgids["PkgWithPostJulia12Support"])
        msg = sprint(show, "text/plain", r)
        @test occursin("Supporting only post-1.2 `julia`", msg)
        @test occursin("ignoring root project", msg)
    end

    @testset "PkgWithoutTestProject" begin
        r = results["PkgWithoutTestProject"]
        @test ispass(r)
        Aqua.test_project_extras(pkgids["PkgWithoutTestProject"])
        msg = sprint(show, "text/plain", r)
        @test occursin("test/Project.toml file does not exist", msg)
    end

    @testset "PkgWithoutProject" begin
        r = results["PkgWithoutProject"]
        @test !ispass(r)
        @test r ⊜ false
        msg = sprint(show, "text/plain", r)
        @test occursin("Project.toml file at project directory does not exist", msg)
    end

end

end  # module
