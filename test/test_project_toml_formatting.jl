module TestProjectTomlFormatting

using Aqua: _analyze_project_toml_formatting_2, ⊜
using Test

@testset "_analyze_project_toml_formatting_2" begin
    path = "DUMMY/PATH"
    @testset "pass" begin
        @test _analyze_project_toml_formatting_2(
            path,
            """
            [deps]
            Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
            """,
        ) ⊜ true
        @test _analyze_project_toml_formatting_2(
            path,
            """
            name = "Aqua"
            uuid = "4c88cf16-eb10-579e-8560-4a9242c79595"
            authors = ["Takafumi Arakaki <aka.tkf@gmail.com>"]
            version = "0.4.7-DEV"

            [deps]
            Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

            [compat]
            julia = "1.0"

            [extras]
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

            [targets]
            test = ["Test"]
            """,
        ) ⊜ true
    end
    @testset "pass: ignore carriage returns" begin
        @test _analyze_project_toml_formatting_2(
            path,
            join([
                """[deps]\r\n""",
                """Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"\r\n""",
                """Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"\r\n""",
            ]),
        ) ⊜ true
    end
    @testset "failure: reversed deps" begin
        t = _analyze_project_toml_formatting_2(
            path,
            """
            [deps]
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
            Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
            """,
        )
        @debug "failure: reversed deps" t
        @test t ⊜ false
        @test occursin("is not in canonical format", string(t))
    end
    @testset "failure: reversed table" begin
        t = _analyze_project_toml_formatting_2(
            path,
            """
            [compat]
            julia = "1.0"

            [deps]
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
            Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
            """,
        )
        @debug "failure: reversed table" t
        @test t ⊜ false
        @test occursin("is not in canonical format", string(t))
    end
    @testset "pass: weakdeps + extensions following Pkg >= 1.7" begin
        @test _analyze_project_toml_formatting_2(
            path,
            """
            name = "Aqua"
            uuid = "4c88cf16-eb10-579e-8560-4a9242c79595"
            authors = ["Takafumi Arakaki <aka.tkf@gmail.com>"]
            version = "0.4.7-DEV"

            [deps]
            Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

            [weakdeps]
            Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

            [extensions]
            AquaRandomExt = "Random"

            [compat]
            julia = "1.0"

            [extras]
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

            [targets]
            test = ["Test"]
            """,
        ) ⊜ true
    end
end

end  # module
