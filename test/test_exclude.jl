module TestExclude

include("preamble.jl")
using Aqua: getobj, normalize_exclude, normalize_and_check_exclude

rootmodule(m::Module) = Base.require(Base.PkgId(m))
rootmodule(x) = rootmodule(parentmodule(x))

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
        modules = [rootmodule(x)]
        @test getobj(normalize_exclude(x), modules) == x
    end

    @testset "$(repr(y))" for (y, modules) in [
        ("Base.foldl", [Base])
        ("Base.Some", [Base])
        ("Core.Tuple", [Core])
        ("Base.Broadcast.Broadcasted", [Base])
    ]
        @test normalize_exclude(getobj(y, modules)) == y
    end
end

@testset "normalize_and_check_exclude" begin
    @testset "$i" for (i, (exclude, modules)) in enumerate([
        ([foldl], [Base])
        (["Base.foldl"], [Base])
        ([foldl, Some], [Base])
        (["Base.foldl", "Base.Some"], [Base])
        ([foldl, Tuple], [Base, Core])
        (["Base.foldl", "Core.Tuple"], [Base, Core])
    ])
        packages = Base.PkgId.(modules)
        @test normalize_and_check_exclude(exclude, packages) isa Vector{String}
    end
end

end  # module
