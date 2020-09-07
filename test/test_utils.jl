module TestUtils

using Aqua: askwargs, format_diff
using Test

@testset "askwargs" begin
    @test_throws ArgumentError("expect `true`") askwargs(false)
    @test askwargs(true) === NamedTuple()
    @test askwargs(()) === NamedTuple()
    @test askwargs((a = 1,)) === (a = 1,)
end

@testset "format_diff" begin
    @testset "normal" begin
        if Sys.which("diff") === nothing
            @info "Comamnd `diff` not found; skip testing `format_diff`."
        else
            diff = format_diff("LABEL_A" => "TEXT_A", "LABEL_B" => "TEXT_B")
            @test occursin("--- LABEL_A", diff)
            @test occursin("+++ LABEL_B", diff)
        end
    end
    @testset "fallback" begin
        diff = withenv("PATH" => "/") do
            format_diff("LABEL_A" => "TEXT_A", "LABEL_B" => "TEXT_B")
        end
        @test occursin("*** LABEL_A ***", diff)
    end
end

end  # module
