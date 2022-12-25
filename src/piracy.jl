module Piracy

using Test: @test
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
is_foreign(@nospecialize(x), pkg::Base.PkgId) = is_foreign(typeof(x), pkg)

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
is_foreign(x::Symbol, pkg::Base.PkgId) = false

is_foreign_module(mod::Module, pkg::Base.PkgId) = Base.PkgId(mod) != pkg

function is_foreign(@nospecialize(T::DataType), pkg::Base.PkgId)
    params = T.parameters
    # For Type{Foo}, we consider it to originate from the same as Foo
    C = getfield(parentmodule(T), nameof(T))
    if C === Type
        @assert length(params) == 1
        return is_foreign(first(params), pkg)
    else
        # Both the type itself and all of its parameters must be foreign
        return is_foreign_module(parentmodule(T), pkg) && all(params) do param
            is_foreign(param, pkg)
        end
    end
end

function is_foreign(@nospecialize(U::UnionAll), pkg::Base.PkgId)
    # We do not consider extending Set{T} to be piracy, if T is not foreign.
    # Extending it goes against Julia style, but it's not piracy IIUC.
    is_foreign(U.body, pkg) && is_foreign(U.var, pkg)
end

is_foreign(@nospecialize(T::TypeVar), pkg::Base.PkgId) = is_foreign(T.ub, pkg)

# Before 1.7, Vararg was a UnionAll, so the UnionAll method will work
@static if VERSION >= v"1.7"
    is_foreign(@nospecialize(T::Core.TypeofVararg), pkg::Base.PkgId) = is_foreign(T.T, pkg)
end

function is_foreign(@nospecialize(U::Union), pkg::Base.PkgId)
    # Even if Foo is local, overloading f(::Union{Foo, Int}) with foreign f 
    # is piracy.
    any(T -> is_foreign(T, pkg), Base.uniontypes(U))
end

function is_pirate(meth::Method)
    method_pkg = Base.PkgId(meth.module)

    signature = meth.sig
    while signature isa UnionAll
        signature = signature.body
    end

    all(param -> is_foreign(param, method_pkg), signature.parameters)
end

hunt(mod::Module; from::Module = mod) = hunt(Base.PkgId(mod); from = from)

function hunt(pkg::Base.PkgId; from::Module)
    filter(all_methods(from)) do method
        is_pirate(method) && Base.PkgId(method.module) === pkg
    end
end

"""
    test_piracy(m::Module)

Test that `m` does not commit type piracy.
"""
function test_piracy(m::Module)
    @test hunt(m) == Method[]
end

end # module
