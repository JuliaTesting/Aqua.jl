push!(LOAD_PATH, joinpath(@__DIR__, "pkgs", "PiracyForeignProject"))

baremodule PiracyModule

using PiracyForeignProject: ForeignType, ForeignParameterizedType

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

# Not piracy
const MyUnion = Union{Int,Foo}
MyUnion(x::Int) = x

export MyUnion

# Piracy
Base.findfirst(::Set{Vector{Char}}, ::Int) = 1
Base.findfirst(::Union{Foo,Bar{Set{Unsigned}},UInt}, ::Tuple{Vararg{String}}) = 1
Base.findfirst(::AbstractChar, ::Set{T}) where {Int <: T <: Integer} = 1

# Piracy, but not for `ForeignType in treat_as_own`
Base.findmax(::ForeignType, x::Int) = x + 1
Base.findmax(::Set{Vector{ForeignType}}, x::Int) = x + 1
Base.findmax(::Union{Foo,ForeignType}, x::Int) = x + 1

# Piracy, but not for `ForeignParameterizedType in treat_as_own`
Base.findmin(::ForeignParameterizedType{Int}, x::Int) = x + 1
Base.findmin(::Set{Vector{ForeignParameterizedType{Int}}}, x::Int) = x + 1
Base.findmin(::Union{Foo,ForeignParameterizedType{Int}}, x::Int) = x + 1

# Assign them names in this module so they can be found by all_methods
a = Base.findfirst
b = Base.findlast
c = Base.findmax
d = Base.findmin
end # PiracyModule

using Aqua: Piracy
using PiracyForeignProject: ForeignType, ForeignParameterizedType

# Get all methods - test length
meths = filter(Piracy.all_methods(PiracyModule)) do m
    m.module == PiracyModule
end

# 2 Foo constructors
# 2 from f
# 1 from MyUnion
# 6 from findlast
# 3 from findfirst
# 3 from findmax
# 3 from findmin
@test length(meths) == 2 + 2 + 1 + 6 + 3 + 3 + 3

# Test what is foreign
BasePkg = Base.PkgId(Base)
CorePkg = Base.PkgId(Core)
ThisPkg = Base.PkgId(PiracyModule)

@test Piracy.is_foreign(Int, BasePkg) # from Core
@test !Piracy.is_foreign(Int, CorePkg) # from Core
@test !Piracy.is_foreign(Set{Int}, BasePkg)
@test !Piracy.is_foreign(Set{Int}, CorePkg)

# Test what is pirate
pirates = filter(m -> Piracy.is_pirate(m), meths)
@test length(pirates) == 3 + 3 + 3
@test all(pirates) do m
    m.name in [:findfirst, :findmax, :findmin]
end

# Test what is pirate (with treat_as_own=[ForeignType])
pirates = filter(m -> Piracy.is_pirate(m; treat_as_own = [ForeignType]), meths)
@test length(pirates) == 3 + 3
@test all(pirates) do m
    m.name in [:findfirst, :findmin]
end

# Test what is pirate (with treat_as_own=[ForeignParameterizedType])
pirates = filter(m -> Piracy.is_pirate(m; treat_as_own = [ForeignParameterizedType]), meths)
@test length(pirates) == 3 + 3
@test all(pirates) do m
    m.name in [:findfirst, :findmax]
end

# Test what is pirate (with treat_as_own=[ForeignType, ForeignParameterizedType])
pirates = filter(
    m -> Piracy.is_pirate(m; treat_as_own = [ForeignType, ForeignParameterizedType]),
    meths,
)
@test length(pirates) == 3
@test all(pirates) do m
    m.name in [:findfirst]
end
