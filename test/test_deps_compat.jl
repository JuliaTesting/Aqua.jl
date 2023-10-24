module TestDepsCompat

include("preamble.jl")
using Aqua: find_missing_deps_compat

const DictSA = Dict{String,Any}

@testset "find_missing_deps_compat" begin
    @testset "pass" begin
        result = find_missing_deps_compat(
            DictSA("deps" => DictSA(), "compat" => DictSA("julia" => "1")),
            "deps",
        )
        @test isempty(result)
        result = find_missing_deps_compat(
            DictSA(
                "deps" => DictSA("PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205"),
                "compat" => DictSA("julia" => "1", "PkgA" => "1.0"),
            ),
            "deps",
        )
        @test isempty(result)
        @testset "does not have `deps`" begin
            result = find_missing_deps_compat(DictSA(), "deps")
            @test isempty(result)
        end
    end
    @testset "failure" begin
        @testset "does not have `compat`" begin
            result = find_missing_deps_compat(
                DictSA("deps" => DictSA("PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205")),
                "deps",
            )
            @test length(result) == 1
            @test [pkg.name for pkg in result] == ["PkgA"]
        end

        @testset "does not specify `compat` for PkgA" begin
            result = find_missing_deps_compat(
                DictSA(
                    "deps" => DictSA("PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205"),
                    "compat" => DictSA("julia" => "1"),
                ),
                "deps",
            )
            @test length(result) == 1
            @test [pkg.name for pkg in result] == ["PkgA"]
        end

        @testset "does not specify `compat` for PkgB" begin
            result = find_missing_deps_compat(
                DictSA(
                    "deps" => DictSA(
                        "PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205",
                        "PkgB" => "3d97d89c-7c41-49ae-981c-14fe13cc7943",
                    ),
                    "compat" => DictSA("julia" => "1", "PkgA" => "1.0"),
                ),
                "deps",
            )
            @test length(result) == 1
            @test [pkg.name for pkg in result] == ["PkgB"]
        end

        @testset "does not specify `compat` for stdlib" begin
            result = find_missing_deps_compat(
                DictSA(
                    "deps" => DictSA(
                        "LinearAlgebra" => "37e2e46d-f89d-539d-b4ee-838fcccc9c8e",
                    ),
                    "compat" => DictSA("julia" => "1"),
                ),
                "deps",
            )
            @test length(result) == 1
            @test [pkg.name for pkg in result] == ["LinearAlgebra"]
        end
    end
end

end  # module
