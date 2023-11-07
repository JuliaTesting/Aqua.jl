askwargs(kwargs) = (; kwargs...)
function askwargs(flag::Bool)
    if !flag
        throw(ArgumentError("expect `true`"))
    end
    return NamedTuple()
end

struct LazyTestResult
    label::String
    message::String
    pass::Bool
end

ispass(result::LazyTestResult) = result.pass

# Infix operator wrapping `ispass` so that the failure case is pretty-printed
⊜(result, yes::Bool) = ispass(result)::Bool == yes

# To be shown via `@test` when failed:
function Base.show(io::IO, result::LazyTestResult)
    print(io, "⟪result: ")
    show(io, MIME"text/plain"(), result)
    print(io, "⟫")
end

function Base.show(io::IO, ::MIME"text/plain", result::LazyTestResult)
    if ispass(result)
        printstyled(io, "✔ PASS"; color = :green, bold = true)
    else
        printstyled(io, "😭 FAILED"; color = :red, bold = true)
    end
    println(io, ": ", result.label)
    for line in eachline(IOBuffer(result.message))
        println(io, " "^4, line)
    end
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

function is_kwcall(signature::DataType)
    @static if VERSION < v"1.9"
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
        return signature.parameters[1] === typeof(Core.kwcall)
    end
end
