module Piracy

using ..Aqua: is_kwcall

using Test: is_in_mods

# based on Test/Test.jl#detect_ambiguities
# https://github.com/JuliaLang/julia/blob/v1.9.1/stdlib/Test/src/Test.jl#L1838-L1896
function all_methods(mods::Module...; skip_deprecated::Bool = true)
    meths = Method[]
    mods = collect(mods)::Vector{Module}

    function examine_def(m::Method)
        is_in_mods(m.module, true, mods) && push!(meths, m)
        nothing
    end

    examine(mt::Core.MethodTable) = Base.visit(examine_def, mt)

    if VERSION >= v"1.12-" && isdefined(Core, :methodtable)
        examine(Core.methodtable)
    elseif VERSION >= v"1.12-" && isdefined(Core, :GlobalMethods)
        # for all versions between JuliaLang/julia#58131 and JuliaLang/julia#59158
        # so just some 1.12 rcs and 1.13 DEVs
        examine(Core.GlobalMethods)
    else
        work = Base.loaded_modules_array()
        filter!(mod -> mod === parentmodule(mod), work) # some items in loaded_modules_array are not top modules (really just Base)
        while !isempty(work)
            mod = pop!(work)
            for name in names(mod; all = true)
                (skip_deprecated && Base.isdeprecated(mod, name)) && continue
                isdefined(mod, name) || continue
                f = Base.unwrap_unionall(getfield(mod, name))
                if isa(f, Module) && f !== mod && parentmodule(f) === mod && nameof(f) === name
                    push!(work, f)
                elseif isa(f, DataType) &&
                       isdefined(f.name, :mt) &&
                       parentmodule(f) === mod &&
                       nameof(f) === name &&
                       f.name.mt !== Symbol.name.mt &&
                       f.name.mt !== DataType.name.mt
                    examine(f.name.mt)
                end
            end
        end
        examine(Symbol.name.mt)
        examine(DataType.name.mt)
    end
    return meths
end

##################################
# Generic fallback for type parameters that are instances, like the 1 in
# Array{T, 1}
is_foreign(@nospecialize(x), pkg::Base.PkgId; treat_as_own) =
    is_foreign(typeof(x), pkg; treat_as_own = treat_as_own)

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
# `Aqua.test_piracies` is to detect only "obvious" piracies, let us play on the
# safe side.
is_foreign(x::Symbol, pkg::Base.PkgId; treat_as_own) = false

is_foreign_module(mod::Module, pkg::Base.PkgId) = Base.PkgId(mod) != pkg

function is_foreign(@nospecialize(T::DataType), pkg::Base.PkgId; treat_as_own)
    params = T.parameters
    # For Type{Foo}, we consider it to originate from the same as Foo
    C = getfield(parentmodule(T), nameof(T))
    if C === Type
        @assert length(params) == 1
        return is_foreign(first(params), pkg; treat_as_own = treat_as_own)
    else
        # Both the type itself and all of its parameters must be foreign
        return !((C in treat_as_own)::Bool) &&
               is_foreign_module(parentmodule(T), pkg) &&
               all(param -> is_foreign(param, pkg; treat_as_own = treat_as_own), params)
    end
end

function is_foreign(@nospecialize(U::UnionAll), pkg::Base.PkgId; treat_as_own)
    # We do not consider extending Set{T} to be piracies, if T is not foreign.
    # Extending it goes against Julia style, but it's not piracies IIUC.
    is_foreign(U.body, pkg; treat_as_own = treat_as_own) &&
        is_foreign(U.var, pkg; treat_as_own = treat_as_own)
end

is_foreign(@nospecialize(T::TypeVar), pkg::Base.PkgId; treat_as_own) =
    is_foreign(T.ub, pkg; treat_as_own = treat_as_own)

# Before 1.7, Vararg was a UnionAll, so the UnionAll method will work
@static if VERSION >= v"1.7-"
    is_foreign(@nospecialize(T::Core.TypeofVararg), pkg::Base.PkgId; treat_as_own) =
        is_foreign(T.T, pkg; treat_as_own = treat_as_own)
end

function is_foreign(@nospecialize(U::Union), pkg::Base.PkgId; treat_as_own)
    # Even if Foo is local, overloading f(::Union{Foo, Int}) with foreign f is piracy.
    any(T -> is_foreign(T, pkg; treat_as_own = treat_as_own), Base.uniontypes(U))
end

function is_foreign_method(@nospecialize(U::Union), pkg::Base.PkgId; treat_as_own)
    # When installing a method for a union type, then we only consider it as
    # foreign if *all* parameters of the union are foreign, i.e. overloading
    # Union{Foo, Int}() is not piracy.
    all(T -> is_foreign(T, pkg; treat_as_own = treat_as_own), Base.uniontypes(U))
end

function is_foreign_method(@nospecialize(x::Any), pkg::Base.PkgId; treat_as_own)
    is_foreign(x, pkg; treat_as_own = treat_as_own)
end

function is_foreign_method(@nospecialize(T::DataType), pkg::Base.PkgId; treat_as_own)
    params = T.parameters
    # For Type{Foo}, we consider it to originate from the same as Foo
    C = getfield(parentmodule(T), nameof(T))
    if C === Type
        @assert length(params) == 1
        return is_foreign_method(first(params), pkg; treat_as_own = treat_as_own)
    end

    # fallback to general code
    return !((T in treat_as_own)::Bool) &&
           !(
               T <: Function &&
               isdefined(T, :instance) &&
               (T.instance in treat_as_own)::Bool
           ) &&
           is_foreign(T, pkg; treat_as_own = treat_as_own)
end


function is_pirate(meth::Method; treat_as_own = Union{Function,Type}[])
    method_pkg = Base.PkgId(meth.module)

    signature = Base.unwrap_unionall(meth.sig)

    function_type_index = 1
    if is_kwcall(meth.sig)
        # kwcall is a special case, since it is not a real function
        # but a wrapper around a function, the third parameter is the original
        # function, its positional arguments follow.
        function_type_index += 2
    end

    # the first parameter in the signature is the function type, and it
    # follows slightly other rules if it happens to be a Union type
    is_foreign_method(
        signature.parameters[function_type_index],
        method_pkg;
        treat_as_own = treat_as_own,
    ) || return false

    return all(
        param -> is_foreign(param, method_pkg; treat_as_own = treat_as_own),
        signature.parameters[function_type_index+1:end],
    )
end

function hunt(mod::Module; skip_deprecated::Bool = true, kwargs...)
    piracies = filter(all_methods(mod; skip_deprecated = skip_deprecated)) do method
        method.module === mod && is_pirate(method; kwargs...)
    end
    sort!(piracies, by = (m -> m.name))
    return piracies
end

end # module

"""
    test_piracies(m::Module)

Test that `m` does not commit type piracies.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test` and shortens the error message.
- `skip_deprecated::Bool = true`: If true, it does not check deprecated methods.
- `treat_as_own = Union{Function, Type}[]`: The types in this container 
  are considered to be "owned" by the module `m`. This is useful for 
  testing packages that deliberately commit some type piracies, e.g. modules
  adding higher-level functionality to a lightweight C-wrapper, or packages
  that are extending `StatsAPI.jl`.
"""
function test_piracies(m::Module; broken::Bool = false, kwargs...)
    v = Piracy.hunt(m; kwargs...)
    if broken
        if !isempty(v)
            printstyled(
                stderr,
                "$(length(v)) instances of possible type-piracy detected. To get a list, set `broken = false`.\n";
                bold = true,
                color = Base.error_color(),
            )
        end
        @test_broken isempty(v)
    else
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
        @test isempty(v)
    end
end
