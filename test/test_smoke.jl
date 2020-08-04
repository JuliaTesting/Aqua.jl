module TestSmoke

using Aqua
Aqua.test_all(Aqua)

using Test
@testset "test_stale_deps" begin
    Aqua.test_stale_deps(Aqua)
end

end  # module
