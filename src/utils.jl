askwargs(kwargs) = (; kwargs...)
function askwargs(flag::Bool)
    if !flag
        throw(ArgumentError("expect `true`"))
    end
    return NamedTuple()
end

aspkgids(pkg::Union{Module,PkgId}) = aspkgids([pkg])
aspkgids(packages) = mapfoldl(aspkgid, push!, packages, init = PkgId[])

aspkgid(pkg::PkgId) = pkg
function aspkgid(m::Module)
    if !ispackage(m)
        error("Non-package (non-toplevel) module is not supported. Got: $m")
    end
    return PkgId(m)
end
function aspkgid(name::Symbol)
    # Maybe `Base.depwarn()`
    return Base.identify_package(String(name))::PkgId
end

ispackage(m::Module) =
    if m in (Base, Core)
        true
    else
        parentmodule(m) == m
    end

function project_toml_path(dir)
    candidates = joinpath.(dir, ["Project.toml", "JuliaProject.toml"])
    i = findfirst(isfile, candidates)
    i === nothing && return candidates[1], false
    return candidates[i], true
end

function root_project_toml(pkg::PkgId)
    srcpath = Base.locate_package(pkg)
    srcpath === nothing && return "", false
    pkgpath = dirname(dirname(srcpath))
    root_project_path, found = project_toml_path(pkgpath)
    return root_project_path, found
end

module _TempModule end

eval_string(code::AbstractString) = include_string(_TempModule, code)

function checked_repr(obj)
    code = repr(obj)
    if !isequal(eval_string(code), obj)
        error("`$repr` is not `repr`-safe")
    end
    return code
end

function is_kwcall(signature::Type)
    @static if VERSION < v"1.9"
        signature = Base.unwrap_unionall(signature)::DataType
        try
            length(signature.parameters) >= 3 || return false
            signature <: Tuple{Function,Any,Any,Vararg} || return false
            (signature.parameters[3] isa DataType && signature.parameters[3] <: Type) ||
                isconcretetype(signature.parameters[3]) ||
                return false
            return signature.parameters[1] === Core.kwftype(signature.parameters[3])
        catch err
            @warn "Please open an issue on JuliaTesting/Aqua.jl for \"is_kwcall\" and the following data:" signature err
            return false
        end
    else
        return signature <: Tuple{typeof(Core.kwcall), Any, Any, Vararg}
    end
end
