module TestUtils

using Aqua: askwargs, enabled
using Test

@testset "askwargs" begin
    @test_throws ArgumentError("expect `true`") askwargs(false)
    @test askwargs(true) === NamedTuple()
    @test askwargs(()) === NamedTuple()
    @test askwargs((a = 1,)) === (a = 1,)
end

@testset "enabled" begin
    @test enabled(true)
    @test enabled((broken = true,))
    @test !enabled(false)
end

end  # module
