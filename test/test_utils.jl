module TestUtils

using Aqua: askwargs
using Test

@testset "askwargs" begin
    @test_throws ArgumentError("expect `true`") askwargs(false)
    @test askwargs(true) === NamedTuple()
    @test askwargs(()) === NamedTuple()
    @test askwargs((a = 1,)) === (a = 1,)
end

end  # module
