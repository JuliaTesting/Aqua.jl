module TestSmoke

using Aqua
Aqua.test_all(Aqua)

using Test
@testset "test_stale_deps" begin
    Aqua.test_stale_deps(Aqua)
end

@testset "test_deps_compat" begin
    Aqua.test_deps_compat(Aqua)
end

end  # module
