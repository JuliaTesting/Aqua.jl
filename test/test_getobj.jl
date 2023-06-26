module TestGetObj

using Aqua.Ambiguities: getobj
using Test

module ModuleA
function f end
end

module ModuleB
using ..ModuleA: ModuleA
ModuleA.f(::Int) = nothing
end

@testset begin
    m, = methods(ModuleA.f, Tuple{Int})
    @test getobj(m) === ModuleA.f
end

end  # module
