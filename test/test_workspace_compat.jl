module TestWorkspaceCompat

include("preamble.jl")
using Aqua:
    admits_julia_before_1_12,
    declares_test_workspace,
    find_workspace_compat_conflicts,
    normalize_workspace_path,
    root_owned_names

const DictSA = Dict{String,Any}

# A root project that puts `test` in its workspace, bounds its own dependency
# `PkgB`, and requires Julia 1.12 or later.
const WORKSPACE_ROOT = DictSA(
    "name" => "PkgA",
    "uuid" => "229717a1-0d13-4dfb-ba8f-049672e31205",
    "deps" => DictSA("PkgB" => "3d97d89c-7c41-49ae-981c-14fe13cc7943"),
    "compat" => DictSA("julia" => "1.12", "PkgB" => "1"),
    "workspace" => DictSA("projects" => ["test"]),
)

# The same project without the workspace declaration.
const STANDALONE_ROOT = DictSA(k => v for (k, v) in WORKSPACE_ROOT if k != "workspace")

# The same project still supporting Julia 1.11, where `[workspace]` is ignored.
const OLD_JULIA_ROOT =
    merge(WORKSPACE_ROOT, DictSA("compat" => DictSA("julia" => "1.11", "PkgB" => "1")))

@testset "normalize_workspace_path" begin
    @test normalize_workspace_path("test") == "test"
    @test normalize_workspace_path("./test") == "test"
    @test normalize_workspace_path("test/") == "test"
    @test normalize_workspace_path("./test/") == "test"
    @test normalize_workspace_path("docs") == "docs"
    @test normalize_workspace_path("lib/SubPkg") == "lib/SubPkg"
end

@testset "declares_test_workspace" begin
    @testset "true" begin
        @test declares_test_workspace(DictSA("workspace" => DictSA("projects" => ["test"])))
        @test declares_test_workspace(
            DictSA("workspace" => DictSA("projects" => ["docs", "./test/"])),
        )
    end
    @testset "false" begin
        @test !declares_test_workspace(DictSA())
        @test !declares_test_workspace(DictSA("workspace" => DictSA()))
        @test !declares_test_workspace(
            DictSA("workspace" => DictSA("projects" => String[])),
        )
        @test !declares_test_workspace(
            DictSA("workspace" => DictSA("projects" => ["docs"])),
        )
        # Only a direct `test` member shares the manifest with the root here.
        @test !declares_test_workspace(
            DictSA("workspace" => DictSA("projects" => ["lib/SubPkg/test"])),
        )
    end
end

@testset "admits_julia_before_1_12" begin
    julia_compat(spec) = DictSA("compat" => DictSA("julia" => spec))
    @testset "admits" begin
        @test admits_julia_before_1_12(DictSA())
        @test admits_julia_before_1_12(DictSA("compat" => DictSA()))
        @test admits_julia_before_1_12(julia_compat("1"))
        @test admits_julia_before_1_12(julia_compat("1.6"))
        @test admits_julia_before_1_12(julia_compat("1.11"))
        @test admits_julia_before_1_12(julia_compat("1.11.9"))
        @test admits_julia_before_1_12(julia_compat("~1.11.9"))
        @test admits_julia_before_1_12(julia_compat("1.10, 1.12"))
        @test admits_julia_before_1_12(julia_compat("1.6 - 1.12"))
    end
    @testset "requires 1.12 or later" begin
        @test !admits_julia_before_1_12(julia_compat("1.12"))
        @test !admits_julia_before_1_12(julia_compat("1.12.1"))
        @test !admits_julia_before_1_12(julia_compat("^1.12"))
        @test !admits_julia_before_1_12(julia_compat("~1.12"))
        @test !admits_julia_before_1_12(julia_compat("=1.12.0"))
        @test !admits_julia_before_1_12(julia_compat("1.12 - 1.14"))
        @test !admits_julia_before_1_12(julia_compat("1.12, 1.13"))
        @test !admits_julia_before_1_12(julia_compat("1.13"))
        @test !admits_julia_before_1_12(julia_compat("2"))
    end
end

@testset "root_owned_names" begin
    @test root_owned_names(DictSA()) == Set{String}()
    @test root_owned_names(DictSA("name" => "PkgA")) == Set(["PkgA"])
    @test root_owned_names(
        DictSA(
            "name" => "PkgA",
            "deps" => DictSA("PkgB" => "3d97d89c-7c41-49ae-981c-14fe13cc7943"),
            "weakdeps" => DictSA("PkgC" => "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"),
            "compat" => DictSA("julia" => "1", "PkgD" => "1"),
        ),
    ) == Set(["PkgA", "PkgB", "PkgC", "PkgD", "julia"])
end

@testset "find_workspace_compat_conflicts" begin
    @testset "pass" begin
        @testset "no compat in test project" begin
            test_prj =
                DictSA("deps" => DictSA("Test" => "8dfed614-e22c-5e08-85e1-65c5234f0b40"))
            @test find_workspace_compat_conflicts(WORKSPACE_ROOT, test_prj) == String[]
        end

        @testset "compat only for test-only deps" begin
            test_prj = DictSA(
                "deps" => DictSA("Test" => "8dfed614-e22c-5e08-85e1-65c5234f0b40"),
                "compat" => DictSA("Test" => "1", "Aqua" => "0.8"),
            )
            @test find_workspace_compat_conflicts(WORKSPACE_ROOT, test_prj) == String[]
        end

        @testset "empty test project" begin
            @test find_workspace_compat_conflicts(WORKSPACE_ROOT, DictSA()) == String[]
        end

        @testset "not a workspace member" begin
            # Outside a workspace the test project has its own manifest, so a
            # repeated bound is not a conflict.
            test_prj = DictSA("compat" => DictSA("PkgB" => "1.5", "julia" => "1.6"))
            @test find_workspace_compat_conflicts(STANDALONE_ROOT, test_prj) == String[]
        end

        @testset "ignored names" begin
            test_prj = DictSA("compat" => DictSA("PkgB" => "1.5", "julia" => "1.6"))
            @test find_workspace_compat_conflicts(
                WORKSPACE_ROOT,
                test_prj;
                ignore = [:PkgB, :julia],
            ) == String[]
        end

        @testset "still supports Julia older than 1.12" begin
            # Julia 1.11 and older ignore `[workspace]`, so the repeated bounds
            # are what constrains the test environment there.
            test_prj = DictSA("compat" => DictSA("PkgB" => "1.5", "julia" => "1.6"))
            @test find_workspace_compat_conflicts(OLD_JULIA_ROOT, test_prj) == String[]

            # A root without any `julia` compat entry admits every Julia version.
            root = DictSA(k => v for (k, v) in WORKSPACE_ROOT if k != "compat")
            @test find_workspace_compat_conflicts(root, test_prj) == String[]
        end
    end

    @testset "failure" begin
        @testset "bounds a root dependency" begin
            test_prj = DictSA("compat" => DictSA("PkgB" => "1.5", "Test" => "1"))
            @test find_workspace_compat_conflicts(WORKSPACE_ROOT, test_prj) == ["PkgB"]
        end

        @testset "bounds julia" begin
            test_prj = DictSA("compat" => DictSA("julia" => "1.6"))
            @test find_workspace_compat_conflicts(WORKSPACE_ROOT, test_prj) == ["julia"]
        end

        @testset "bounds the package itself" begin
            test_prj = DictSA("compat" => DictSA("PkgA" => "1"))
            @test find_workspace_compat_conflicts(WORKSPACE_ROOT, test_prj) == ["PkgA"]
        end

        @testset "bounds a name the root lists without compat" begin
            root = DictSA(
                "name" => "PkgA",
                "deps" => DictSA("PkgB" => "3d97d89c-7c41-49ae-981c-14fe13cc7943"),
                "compat" => DictSA("julia" => "1.12"),
                "workspace" => DictSA("projects" => ["test"]),
            )
            test_prj = DictSA("compat" => DictSA("PkgB" => "1.5"))
            @test find_workspace_compat_conflicts(root, test_prj) == ["PkgB"]
        end

        @testset "several offenders are sorted" begin
            test_prj = DictSA(
                "compat" => DictSA(
                    "PkgB" => "1.5",
                    "PkgA" => "1",
                    "julia" => "1.6",
                    "Test" => "1",
                ),
            )
            @test find_workspace_compat_conflicts(WORKSPACE_ROOT, test_prj) ==
                  ["PkgA", "PkgB", "julia"]
        end

        @testset "partially ignored" begin
            test_prj = DictSA("compat" => DictSA("PkgB" => "1.5", "julia" => "1.6"))
            @test find_workspace_compat_conflicts(
                WORKSPACE_ROOT,
                test_prj;
                ignore = [:PkgB],
            ) == ["julia"]
        end
    end
end

with_sample_pkgs() do
    @testset "PkgWithWorkspaceCompatConflict" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithWorkspaceCompatConflict"]
        println("### Expected output START ###")
        @test find_workspace_compat_conflicts(pkg) == ["Pkg", "julia"]
        results = @testtestset begin
            Aqua.test_workspace_compat(pkg)
        end
        @test length(results) == 1
        @test results[1] isa Test.Fail

        @testset "broken" begin
            results = @testtestset begin
                Aqua.test_workspace_compat(pkg; broken = true)
            end
            @test length(results) == 1
            @test results[1] isa Test.Broken
        end
        println("### Expected output END ###")

        @testset "ignore" begin
            @test find_workspace_compat_conflicts(pkg; ignore = [:Pkg, :julia]) == String[]
        end
    end

    @testset "PkgWithCleanWorkspaceCompat" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithCleanWorkspaceCompat"]
        @test find_workspace_compat_conflicts(pkg) == String[]
        Aqua.test_workspace_compat(pkg)
    end

    @testset "PkgWithTestCompatOutsideWorkspace" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithTestCompatOutsideWorkspace"]
        @test find_workspace_compat_conflicts(pkg) == String[]
        Aqua.test_workspace_compat(pkg)
    end

    @testset "PkgWithWorkspaceCompatOnOldJulia" begin
        # Same offending test compat as PkgWithWorkspaceCompatConflict, but the
        # root still supports Julia 1.11: the check is a no-op and says so.
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithWorkspaceCompatOnOldJulia"]
        noop_notice = (:info, r"test_workspace_compat is a no-op for .*julia = \"1.11\"")
        conflicts = @test_logs noop_notice find_workspace_compat_conflicts(pkg)
        @test conflicts == String[]
        @test_logs noop_notice Aqua.test_workspace_compat(pkg)
    end

    @testset "PkgWithoutTestProject" begin
        pkg = AquaTesting.SAMPLE_PKG_BY_NAME["PkgWithoutTestProject"]
        @test find_workspace_compat_conflicts(pkg) == String[]
        Aqua.test_workspace_compat(pkg)
    end
end

end  # module
