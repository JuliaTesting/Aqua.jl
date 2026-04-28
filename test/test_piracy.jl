push!(LOAD_PATH, joinpath(@__DIR__, "pkgs", "PiracyForeignProject"))

baremodule PiracyModule

using PiracyForeignProject:
    ForeignType,
    ForeignParameterizedType,
    ForeignNonSingletonType,
    ForeignSymbolParamType,
    ForeignTaggedType

using Base:
    Base,
    Set,
    AbstractSet,
    Integer,
    Val,
    Vararg,
    Vector,
    Unsigned,
    UInt,
    String,
    Tuple,
    AbstractChar

struct Foo end
struct Bar{T<:AbstractSet{<:Integer}} end

# Not piracy: Function defined here
f(::Int, ::Union{String,Char}) = 1
f(::Int) = 2
Foo(::Int) = Foo()

# Not piracy: At least one argument is local
Base.findlast(::Foo, x::Int) = x + 1
Base.findlast(::Set{Foo}, x::Int) = x + 1
Base.findlast(::Type{Val{Foo}}, x::Int) = x + 1
Base.findlast(::Tuple{Vararg{Bar{Set{Int}}}}, x::Int) = x + 1
Base.findlast(::Val{:foo}, x::Int) = x + 1
Base.findlast(::ForeignParameterizedType{Foo}, x::Int) = x + 1
# Not piracy: :caller_tag is not defined in PiracyForeignProject's type aliases,
# so it is treated as a user-defined dispatch tag (like Val{:foo} above)
Base.findlast(::ForeignSymbolParamType{:caller_tag, T}, x::Int) where T = x + 1

# Not piracy
const MyUnion = Union{Int,Foo}
MyUnion(x::Int) = x
MyUnion(; x::Int) = x

export MyUnion

# Piracy
Base.findfirst(::Set{Vector{Char}}, ::Int) = 1
Base.findfirst(::Union{Foo,Bar{Set{Unsigned}},UInt}, ::Tuple{Vararg{String}}) = 1
Base.findfirst(::AbstractChar, ::Set{T}) where {Int <: T <: Integer} = 1
(::ForeignType)(x::Int8) = x + 1
(::ForeignNonSingletonType)(x::Int8) = x + 1

# Piracy, but not for `ForeignType in treat_as_own`
Base.findmax(::ForeignType, x::Int) = x + 1
Base.findmax(::Set{Vector{ForeignType}}, x::Int) = x + 1
Base.findmax(::Union{Foo,ForeignType}, x::Int) = x + 1

# Piracy, but not for `ForeignParameterizedType in treat_as_own`
Base.findmin(::ForeignParameterizedType{Int}, x::Int) = x + 1
Base.findmin(::Set{Vector{ForeignParameterizedType{Int}}}, x::Int) = x + 1
Base.findmin(::Union{Foo,ForeignParameterizedType{Int}}, x::Int) = x + 1

# Piracy: ForeignTaggedType = ForeignSymbolParamType{:tag, T} is a type alias
# defined in PiracyForeignProject, so :tag is structural — not a user-defined
# dispatch tag — and must not suppress piracy detection.
# Compare with Val{:foo} and ForeignSymbolParamType{:caller_tag,T} above.
Base.findlast(::ForeignTaggedType{T}, x::Int) where T = x + 1

end # PiracyModule

using Aqua: Piracy
using PiracyForeignProject:
    ForeignType,
    ForeignParameterizedType,
    ForeignNonSingletonType,
    ForeignSymbolParamType,
    ForeignTaggedType

# Get all methods - test length
meths = filter(Piracy.all_methods(PiracyModule)) do m
    m.module == PiracyModule
end

@test length(meths) ==
      2 + # Foo constructors
      1 + # Bar constructor
      2 + # f
      4 + # MyUnion (incl. kwcall)
      8 + # findlast (7 non-piracy + 1 ForeignTaggedType piracy)
      3 + # findfirst
      1 + # ForeignType callable
      1 + # ForeignNonSingletonType callable
      3 + # findmax
      3   # findmin

# Test what is foreign
BasePkg = Base.PkgId(Base)
CorePkg = Base.PkgId(Core)
ThisPkg = Base.PkgId(PiracyModule)

@test Piracy.is_foreign(Int, BasePkg; treat_as_own = []) # from Core
@test !Piracy.is_foreign(Int, CorePkg; treat_as_own = []) # from Core
@test !Piracy.is_foreign(Set{Int}, BasePkg; treat_as_own = [])
@test !Piracy.is_foreign(Set{Int}, CorePkg; treat_as_own = [])

# Test what is pirate
pirates = Piracy.hunt(PiracyModule)
@test length(pirates) ==
      3 + # findfirst
      3 + # findmax
      3 + # findmin
      1 + # ForeignType callable
      1 + # ForeignNonSingletonType callable
      1   # findlast on ForeignTaggedType — :tag is structural in PiracyForeignProject
@test all(pirates) do m
    m.name in [:findfirst, :findmax, :findmin, :ForeignType, :ForeignNonSingletonType, :findlast]
end

# Specifically verify which findlast is the pirate: the one whose arg2 contains
# :tag (structural — defined in PiracyForeignProject's ForeignTaggedType alias)
# must be piracy, while the one with :caller_tag (user-defined) must not be.
let arg2_params = m -> let sig = Base.unwrap_unionall(m.sig), p2 = sig.parameters[2]
        p2 isa DataType ? p2.parameters : ()
    end
    tagged_findlast  = filter(m -> m.name === :findlast && :tag        in arg2_params(m), meths)
    caller_findlast  = filter(m -> m.name === :findlast && :caller_tag in arg2_params(m), meths)
    @test length(tagged_findlast)  == 1 &&  Piracy.is_pirate(only(tagged_findlast))
    @test length(caller_findlast)  == 1 && !Piracy.is_pirate(only(caller_findlast))
end

# Test what is pirate (with treat_as_own=[ForeignType])
pirates = Piracy.hunt(PiracyModule, treat_as_own = [ForeignType])
@test length(pirates) ==
      3 + # findfirst
      3 + # findmin
      1 + # ForeignNonSingletonType callable
      1   # findlast on ForeignSymbolParamType{:tag,T}
@test all(pirates) do m
    m.name in [:findfirst, :findmin, :ForeignNonSingletonType, :findlast]
end

# Test what is pirate (with treat_as_own=[ForeignParameterizedType])
pirates = Piracy.hunt(PiracyModule, treat_as_own = [ForeignParameterizedType])
@test length(pirates) ==
      3 + # findfirst
      3 + # findmax
      1 + # ForeignType callable
      1 + # ForeignNonSingletonType callable
      1   # findlast on ForeignSymbolParamType{:tag,T}
@test all(pirates) do m
    m.name in [:findfirst, :findmax, :ForeignType, :ForeignNonSingletonType, :findlast]
end

# Test what is pirate (with treat_as_own=[ForeignType, ForeignParameterizedType])
pirates = filter(
    m -> Piracy.is_pirate(m; treat_as_own = [ForeignType, ForeignParameterizedType]),
    meths,
)
@test length(pirates) ==
      3 + # findfirst
      1 + # ForeignNonSingletonType callable
      1   # findlast on ForeignSymbolParamType{:tag,T}
@test all(pirates) do m
    m.name in [:findfirst, :ForeignNonSingletonType, :findlast]
end

# Test what is pirate (with treat_as_own=[Base.findfirst, Base.findmax])
pirates = Piracy.hunt(PiracyModule, treat_as_own = [Base.findfirst, Base.findmax])
@test length(pirates) ==
      3 + # findmin
      1 + # ForeignType callable
      1 + # ForeignNonSingletonType callable
      1   # findlast on ForeignSymbolParamType{:tag,T}
@test all(pirates) do m
    m.name in [:findmin, :ForeignType, :ForeignNonSingletonType, :findlast]
end

# Test what is pirate (excluding a cover of everything)
pirates = filter(
    m -> Piracy.is_pirate(
        m;
        treat_as_own = [
            ForeignType,
            ForeignParameterizedType,
            ForeignNonSingletonType,
            ForeignSymbolParamType,
            Base.findfirst,
        ],
    ),
    meths,
)
@test length(pirates) == 0
