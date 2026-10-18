module TestExclude

include("preamble.jl")
using Base: PkgId
using Aqua: getexclude, normalize_exclude, normalize_exclude_obj, normalize_and_check_exclude, rootmodule, reprexclude

@assert parentmodule(Tuple) === Core
@assert parentmodule(foldl) === Base
@assert parentmodule(Some) === Base
@assert parentmodule(Broadcast.Broadcasted) === Base.Broadcast
@assert rootmodule(Broadcast.Broadcasted) === Base

@testset "roundtrip" begin
    @testset for x in Any[
        foldl
        Some
        Tuple
        Broadcast.Broadcasted
        nothing
        Any
    ]
        @test getexclude(normalize_exclude(x)) === normalize_exclude_obj(x)
    end
    @test_throws ErrorException normalize_and_check_exclude(Any[Pair{Int}])

    @testset "$(repr(last(spec)))" for spec in [
        (PkgId(Base) => "Base.#foldl")
        (PkgId(Base) => "Base.Some")
        (PkgId(Core) => "Core.Tuple")
        (PkgId(Base) => "Base.Broadcast.Broadcasted")
        (PkgId(Core) => "Core.Nothing")
        (PkgId(Core) => "Core.Any")
    ]
        @test normalize_exclude(getexclude(spec)) === spec
    end
end

@testset "normalize_and_check_exclude" begin
    @testset "$i" for (i, exclude) in enumerate([Any[foldl], Any[foldl, Some], Any[foldl, Tuple]])
        local specs
        @test (specs = normalize_and_check_exclude(exclude)) isa Vector
        @test Base.include_string(@__MODULE__, reprexclude(specs)) == specs
    end
end

end  # module
