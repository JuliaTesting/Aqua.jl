baremodule PiracyModule

using Base: Base, Set, AbstractSet, Integer, Val, Vararg, Vector, Unsigned, UInt, String,
 Tuple, AbstractChar

struct Foo end
struct Bar{T <: AbstractSet{<:Integer}} end

# Not piracy: Function defined here
f(::Int, ::Union{String, Char}) = 1
f(::Int) = 2
Foo(::Int) = Foo()

# Not piracy: At least one argument is local
Base.findlast(::Foo, x::Int) = x + 1
Base.findlast(::Set{Foo}, x::Int) = x + 1
Base.findlast(::Type{Val{Foo}}, x::Int) = x + 1
Base.findlast(::Tuple{Vararg{Bar{Set{Int}}}}, x::Int) = x + 1
Base.findlast(::Val{:foo}, x::Int) = x + 1

# Piracy
Base.findfirst(::Set{Vector{Char}}, ::Int) = 1
Base.findfirst(::Union{Foo, Bar{Set{Unsigned}}, UInt}, ::Tuple{Vararg{String}}) = 1
Base.findfirst(::AbstractChar, ::Set{T}) where {Int <: T <: Integer} = 1

# Assign them names in this module so they can be found by all_methods
x = Base.findfirst
y = Base.findlast
end # PiracyModule

using Aqua: Piracy

# Get all methods - test length
meths = Piracy.all_methods(PiracyModule)

# 2 Foo constructors
# 2 from f
# 5 from findlast
# 3 from findfirst
@test length(meths) == 2 + 2 + 5 + 3

# Test what is foreign
BasePkg = Base.PkgId(Base)
CorePkg = Base.PkgId(Core)
ThisPkg = Base.PkgId(PiracyModule)

@test Piracy.is_foreign(Int, BasePkg) # from Core
@test !Piracy.is_foreign(Int, CorePkg) # from Core
@test !Piracy.is_foreign(Set{Int}, BasePkg)
@test !Piracy.is_foreign(Set{Int}, CorePkg)

# Test what is pirate
pirates = filter(Piracy.is_pirate, meths)
@test length(pirates) == 3
@test all(pirates) do m
    m.name === :findfirst
end
