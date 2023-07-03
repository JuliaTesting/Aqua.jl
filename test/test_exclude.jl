module TestExclude

include("preamble.jl")

using Base: PkgId

using Aqua.Ambiguities:
    getobj, normalize_exclude, normalize_and_check_exclude, rootmodule, reprexclude

@assert parentmodule(Tuple) === Core
@assert parentmodule(foldl) === Base
@assert parentmodule(Some) === Base
@assert parentmodule(Broadcast.Broadcasted) === Base.Broadcast
@assert rootmodule(Broadcast.Broadcasted) === Base

@testset "roundtrip" begin
    @testset for x in [
        foldl
        Some
        Tuple
        Broadcast.Broadcasted
    ]
        @test getobj(normalize_exclude(x)) == x
    end

    @testset "$(repr(last(spec)))" for spec in [
        (PkgId(Base) => "Base.foldl")
        (PkgId(Base) => "Base.Some")
        (PkgId(Core) => "Core.Tuple")
        (PkgId(Base) => "Base.Broadcast.Broadcasted")
    ]
        @test normalize_exclude(getobj(spec)) === spec
    end
end

@testset "normalize_and_check_exclude" begin
    @testset "$i" for (i, exclude) in enumerate([[foldl], [foldl, Some], [foldl, Tuple]])
        local specs
        @test (specs = normalize_and_check_exclude(exclude)) isa Vector
        @test Base.include_string(@__MODULE__, reprexclude(specs)) == specs
    end
end

end  # module
