module Piracy

using Test: @test

const Callable = Union{Function, Type}
const DEFAULT_PKGS = (Base.PkgId(Base), Base.PkgId(Core))

function all_methods(
    mod::Module,
    done_modules::Base.IdSet{Module},     # cached to prevent inf loops
    done_callables::Base.IdSet{Callable}, # cached to prevent inf loops
    result::Vector{Method},
    filter_default::Bool
)::Vector{Method}
    push!(done_modules, mod)
    for name in names(mod; all=true, imported=true)
        # names can list undefined symbols which cannot be eval'd
        isdefined(mod, name) || continue
        
        # Skip closures
        first(String(name)) == '#' && continue
        val = Core.eval(mod, name)
        
        if val isa Module && !in(val, done_modules)
            all_methods(val, done_modules, done_callables, result, filter_default)
        elseif val isa Callable && !in(val, done_callables)
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

function all_methods(mod::Module; filter_default::Bool=true)
    all_methods(mod, Base.IdSet{Module}(), Base.IdSet{Callable}(), Method[], filter_default)
end

##################################
# Generic fallback for type parameters that are instances, like the 1 in
# Array{T, 1}
is_foreign(@nospecialize(x), pkg::Base.PkgId) = is_foreign(typeof(x), pkg)

# Symbols can be used as type params - we assume these are unique and not
# piracy
is_foreign(x::Symbol, pkg::Base.PkgId) = false
is_foreign(mod::Module, pkg::Base.PkgId) = Base.PkgId(mod) != pkg

function is_foreign(@nospecialize(T::DataType), pkg::Base.PkgId)
    params = T.parameters
    # For Type{Foo}, we consider it to originate from the same as Foo
    if Base.typename(T).wrapper === Type
        @assert length(params) == 1
        return is_foreign(first(params), pkg)
    else
        # Both the type itself and all of its parameters must be foreign
        return is_foreign(T.name.module, pkg) && all(params) do param
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

#######################################
hunt(;from::Module=Main) = filter(is_pirate, all_methods(from))
hunt(mod::Module; from::Module=Main) = hunt(Base.PkgId(mod); from=from)

function hunt(pkg::Base.PkgId; from::Module=Main)
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
