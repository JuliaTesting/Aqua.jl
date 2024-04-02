module TestProjectExtras

include("preamble.jl")
using Aqua: is_julia12_or_later
using Base: PkgId, UUID

@testset "is_julia12_or_later" begin
    @test is_julia12_or_later("1.2")
    @test is_julia12_or_later("1.3")
    @test is_julia12_or_later("1.3, 1.4")
    @test is_julia12_or_later("1.3 - 1.4, 1.6")
    @test !is_julia12_or_later("1")
    @test !is_julia12_or_later("1.1")
    @test !is_julia12_or_later("1.0 - 1.1")
    @test !is_julia12_or_later("1.0 - 1.3")
end

with_sample_pkgs() do
    @testset "PkgWithIncompatibleTestProject" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithIncompatibleTestProject"]
        result = Aqua.analyze_project_extras(pkg)
        @test !isempty(result)
        @test any(
            msg -> occursin(
                "Root and test projects should be consistent for projects supporting Julia <= 1.1.",
                msg,
            ),
            result,
        )
        @test any(
            msg ->
                occursin("Test dependencies not in root project", msg) &&
                    occursin("Random [9a3f8284-a2c9-5f02-9a11-845980a1fd5c]", msg),
            result,
        )
        @test any(
            msg ->
                occursin("Dependencies not in test project", msg) &&
                    occursin("REPL [3fa0cd96-eef1-5676-8a61-b3b8758bbffb]", msg),
            result,
        )
        @test !any(msg -> occursin("Test [", msg), result)
    end

    @testset "PkgWithCompatibleTestProject" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithCompatibleTestProject"]
        result = Aqua.analyze_project_extras(pkg)
        @test isempty(result)
    end

    @testset "PkgWithPostJulia12Support" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithPostJulia12Support"]
        result = Aqua.analyze_project_extras(pkg)
        @test isempty(result)
    end

    @testset "PkgWithoutTestProject" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithoutTestProject"]
        result = Aqua.analyze_project_extras(pkg)
        @test isempty(result)
    end
end

end  # module
