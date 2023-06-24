module Piracy

using Test: @test, @test_broken
using ..Aqua: walkmodules

const DEFAULT_PKGS = (Base.PkgId(Base), Base.PkgId(Core))

function all_methods!(
    mod::Module,
    done_callables::Base.IdSet{Any},      # cached to prevent duplicates
    result::Vector{Method},
    filter_default::Bool,
)::Vector{Method}
    for name in names(mod; all = true, imported = true)
        # names can list undefined symbols which cannot be eval'd
        isdefined(mod, name) || continue

        # Skip closures
        startswith(String(name), "#") && continue
        val = getfield(mod, name)

        if !in(val, done_callables)
            # In old versions of Julia, Vararg errors when methods is called on it
            val === Vararg && continue
            for method in methods(val)
                # Default filtering removes all methods defined in DEFAULT_PKGs,
                # since these may pirate each other.
                if !(filter_default && in(Base.PkgId(method.module), DEFAULT_PKGS))
                    push!(result, method)
                end
            end
            push!(done_callables, val)
        end
    end
    result
end

function all_methods(mod::Module; filter_default::Bool = true)
    result = Method[]
    done_callables = Base.IdSet()
    walkmodules(mod) do mod
        all_methods!(mod, done_callables, result, filter_default)
    end
    return result
end

##################################
# Generic fallback for type parameters that are instances, like the 1 in
# Array{T, 1}
is_foreign(@nospecialize(x), pkg::Base.PkgId; treat_as_own::Vector{<:Type} = Type[]) =
    is_foreign(typeof(x), pkg; treat_as_own)

# Symbols can be used as type params - we assume these are unique and not
# piracy.  This implies that we have
#
#     julia> Aqua.Piracy.is_foreign(1, Base.PkgId(Aqua))
#     true
# 
#     julia> Aqua.Piracy.is_foreign(:hello, Base.PkgId(Aqua))
#     false
#
# and thus
#
#     julia> Aqua.Piracy.is_foreign(Val{1}, Base.PkgId(Aqua))
#     true
# 
#     julia> Aqua.Piracy.is_foreign(Val{:hello}, Base.PkgId(Aqua))
#     false
#
# Admittedly, this asymmetry is rather worrisome.  We do need to treat 1 foreign
# to consider `Vector{Char}` (i.e., `Array{Char,1}`) foreign.  This may suggest
# to treat the `Symbol` type foreign as well.  However, it means that we treat
# definition such as
#
#     ForeignModule.api_function(::Val{:MyPackageName}) = ...
# 
# as a type piracy even if this is actually the intended use-case (which is not
# a crazy API).  The symbol name may also come from `gensym`.  Since the aim of
# `Aqua.test_piracy` is to detect only "obvious" piracy, let us play on the
# safe side.
is_foreign(x::Symbol, pkg::Base.PkgId; treat_as_own::Vector{<:Type} = Type[]) = false

is_foreign_module(mod::Module, pkg::Base.PkgId) = Base.PkgId(mod) != pkg

function is_foreign(
    @nospecialize(T::DataType),
    pkg::Base.PkgId;
    treat_as_own::Vector{<:Type} = Type[],
)
    params = T.parameters
    # For Type{Foo}, we consider it to originate from the same as Foo
    C = getfield(parentmodule(T), nameof(T))
    if C === Type
        @assert length(params) == 1
        return is_foreign(first(params), pkg; treat_as_own)
    else
        # Both the type itself and all of its parameters must be foreign
        return (!(C in treat_as_own) && is_foreign_module(parentmodule(T), pkg)) &&
               all(param -> is_foreign(param, pkg; treat_as_own), params)
    end
end

function is_foreign(
    @nospecialize(U::UnionAll),
    pkg::Base.PkgId;
    treat_as_own::Vector{<:Type} = Type[],
)
    # We do not consider extending Set{T} to be piracy, if T is not foreign.
    # Extending it goes against Julia style, but it's not piracy IIUC.
    is_foreign(U.body, pkg; treat_as_own) && is_foreign(U.var, pkg; treat_as_own)
end

is_foreign(
    @nospecialize(T::TypeVar),
    pkg::Base.PkgId;
    treat_as_own::Vector{<:Type} = Type[],
) = is_foreign(T.ub, pkg; treat_as_own)

# Before 1.7, Vararg was a UnionAll, so the UnionAll method will work
@static if VERSION >= v"1.7"
    is_foreign(
        @nospecialize(T::Core.TypeofVararg),
        pkg::Base.PkgId;
        treat_as_own::Vector{<:Type} = Type[],
    ) = is_foreign(T.T, pkg; treat_as_own)
end

function is_foreign(
    @nospecialize(U::Union),
    pkg::Base.PkgId;
    treat_as_own::Vector{<:Type} = Type[],
)
    # Even if Foo is local, overloading f(::Union{Foo, Int}) with foreign f
    # is piracy.
    any(T -> is_foreign(T, pkg; treat_as_own), Base.uniontypes(U))
end

function is_foreign_method(
    @nospecialize(U::Union),
    pkg::Base.PkgId;
    treat_as_own::Vector{<:Type} = Type[],
)
    # When installing a method for a union type, then we only consider it as
    # foreign if *all* parameters of the union are foreign, i.e. overloading
    # Union{Foo, Int}() is not piracy.
    all(T -> is_foreign(T, pkg; treat_as_own), Base.uniontypes(U))
end

function is_foreign_method(
    @nospecialize(x::Any),
    pkg::Base.PkgId;
    treat_as_own::Vector{<:Type} = Type[],
)
    is_foreign(x, pkg; treat_as_own)
end

function is_foreign_method(
    @nospecialize(T::DataType),
    pkg::Base.PkgId;
    treat_as_own::Vector{<:Type} = Type[],
)
    params = T.parameters
    # For Type{Foo}, we consider it to originate from the same as Foo
    C = getfield(parentmodule(T), nameof(T))
    if C === Type
        @assert length(params) == 1
        return is_foreign_method(first(params), pkg; treat_as_own)
    end

    # fallback to general code
    return is_foreign(T, pkg; treat_as_own)
end


function is_pirate(meth::Method; treat_as_own::Vector{<:Type} = Type[])
    method_pkg = Base.PkgId(meth.module)

    signature = Base.unwrap_unionall(meth.sig)

    # the first parameter in the signature is the function type, and it
    # follows slightly other rules if it happens to be a Union type
    is_foreign_method(signature.parameters[1], method_pkg; treat_as_own) || return false

    all(param -> is_foreign(param, method_pkg; treat_as_own), signature.parameters[2:end])
end

hunt(mod::Module; from::Module = mod, kwargs...) =
    hunt(Base.PkgId(mod); from = from, kwargs...)

function hunt(pkg::Base.PkgId; from::Module, kwargs...)
    filter(all_methods(from)) do method
        Base.PkgId(method.module) === pkg && is_pirate(method, kwargs...)
    end
end

"""
    test_piracy(m::Module)

Test that `m` does not commit type piracy.
See [Julia documentation](https://docs.julialang.org/en/v1/manual/style-guide/#Avoid-type-piracy) for more information about type piracy.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test`.
- `treat_as_own::Vector{<:Type} = Type[]`: The types in this vector are considered
  to be "owned" by the module `m`. This is useful for testing packages that
  deliberately commit some type piracy, e.g. modules adding higher-level
  functionality to a lightweight C-wrapper.
"""
function test_piracy(m::Module; broken::Bool = false, kwargs...)
    v = hunt(m; kwargs...)
    if !isempty(v)
        printstyled(
            stderr,
            "Possible type-piracy detected:\n";
            bold = true,
            color = Base.error_color(),
        )
        show(stderr, MIME"text/plain"(), v)
        println(stderr)
    end
    if broken
        @test_broken isempty(v)
    else
        @test isempty(v)
    end
end

end # module
