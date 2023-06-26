module TestDepsCompat

include("preamble.jl")

using Aqua: ⊜
using Aqua.DepsCompat: _analyze_deps_compat_2

const DictSA = Dict{String,Any}

@testset "_analyze_deps_compat_2" begin
    pkg = Base.PkgId(Base.UUID(42), "TargetPkg")
    root_project_path = "DUMMY_PATH"
    @testset "pass" begin
        @test _analyze_deps_compat_2(
            pkg,
            root_project_path,
            DictSA("deps" => DictSA(), "compat" => DictSA("julia" => "1")),
        ) ⊜ true
        @test _analyze_deps_compat_2(
            pkg,
            root_project_path,
            DictSA(
                "deps" => DictSA("SHA" => "ea8e919c-243c-51af-8825-aaa63cd721ce"),
                "compat" => DictSA("julia" => "1"),
            ),
        ) ⊜ true
        @test _analyze_deps_compat_2(
            pkg,
            root_project_path,
            DictSA(
                "deps" => DictSA("PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205"),
                "compat" => DictSA("julia" => "1", "PkgA" => "1.0"),
            ),
        ) ⊜ true
        @testset "does not have `deps`" begin
            # Not sure if it should fail or passs:
            t = _analyze_deps_compat_2(pkg, root_project_path, DictSA())
            @test t ⊜ true
            @test occursin("does not have `deps`", string(t))
        end
    end
    @testset "failure" begin
        @testset "does not have `compat`" begin
            t = _analyze_deps_compat_2(
                pkg,
                root_project_path,
                DictSA("deps" => DictSA("PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205")),
            )
            @test t ⊜ false
            @test occursin("does not have `compat`", string(t))
        end

        @testset "does not specify `compat` for PkgA" begin
            t = _analyze_deps_compat_2(
                pkg,
                root_project_path,
                DictSA(
                    "deps" => DictSA("PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205"),
                    "compat" => DictSA("julia" => "1"),
                ),
            )
            @test t ⊜ false
            @test occursin("does not specify `compat` for", string(t))
            @test occursin("PkgA", string(t))
        end

        @testset "does not specify `compat` for PkgB" begin
            t = _analyze_deps_compat_2(
                pkg,
                root_project_path,
                DictSA(
                    "deps" => DictSA(
                        "PkgA" => "229717a1-0d13-4dfb-ba8f-049672e31205",
                        "PkgB" => "3d97d89c-7c41-49ae-981c-14fe13cc7943",
                    ),
                    "compat" => DictSA("julia" => "1", "PkgA" => "1.0"),
                ),
            )
            @test t ⊜ false
            @test occursin("does not specify `compat` for", string(t))
            @test occursin("PkgB", string(t))
        end
    end
end

end  # module
