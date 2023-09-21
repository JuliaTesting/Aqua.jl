if !@isdefined(isnothing)
    isnothing(x) = x === nothing
end

splitlines(str; kwargs...) = readlines(IOBuffer(str); kwargs...)

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

function root_project_or_failed_lazytest(pkg::PkgId)
    label = "$pkg"

    srcpath = Base.locate_package(pkg)
    if srcpath === nothing
        return LazyTestResult(
            label,
            """
            Package $pkg does not have a corresponding source file.
            """,
            false,
        )
    end

    pkgpath = dirname(dirname(srcpath))
    root_project_path, found = project_toml_path(pkgpath)
    if !found
        return LazyTestResult(
            label,
            """
            Project.toml file at project directory does not exist:
            $root_project_path
            """,
            false,
        )
    end
    return root_project_path
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



function get_stdlib_list()
    @static if VERSION >= v"1.5.0-DEV.200"
        result = Pkg.Types.stdlibs()
    elseif VERSION >= v"1.1.0-DEV.800"
        result = Pkg.Types.stdlib()
    else
        result = Pkg.Types.gather_stdlib_uuids()
    end

    @static if VERSION >= v"1.7.0-DEV.1261"
        # format: Dict{Base.UUID, Tuple{String, Union{Nothing, VersionNumber}}}
        libs = [PkgId(first(entry), first(last(entry))) for entry in result]
    else
        # format Dict{Base.UUID, String}
        libs = [PkgId(first(entry), last(entry)) for entry in result]
    end
    return libs
end

const _project_key_order = [
    "name",
    "uuid",
    "keywords",
    "license",
    "desc",
    "deps",
    "weakdeps",
    "extensions",
    "compat",
    "extras",
    "targets",
]
project_key_order(key::String) =
    something(findfirst(x -> x == key, _project_key_order), length(_project_key_order) + 1)

print_project(io, dict) =
    TOML.print(io, dict, sorted = true, by = key -> (project_key_order(key), key))

ensure_exception(e::Exception) = e
ensure_exception(x) = ErrorException(string(x))

"""
    trydiff(label_a => text_a, label_b => text_b) -> string or exception
"""
function trydiff(
    (label_a, text_a)::Pair{<:AbstractString,<:AbstractString},
    (label_b, text_b)::Pair{<:AbstractString,<:AbstractString},
)
    # TODO: use a pure-Julia function
    cmd = `diff --label $label_a --label $label_b -u`
    mktemp() do path_a, io_a
        print(io_a, text_a)
        close(io_a)
        mktemp() do path_b, io_b
            print(io_b, text_b)
            close(io_b)
            try
                return read(ignorestatus(`$cmd $path_a $path_b`), String)
            catch err
                return ensure_exception(err)
            end
        end
    end
end

function format_diff(
    (label_a, text_a)::Pair{<:AbstractString,<:AbstractString},
    (label_b, text_b)::Pair{<:AbstractString,<:AbstractString},
)
    diff = trydiff(label_a => text_a, label_b => text_b)
    diff isa AbstractString && return diff
    # Fallback:
    return """
    *** $label_a ***
    $text_a

    *** $label_b ***
    $text_b
    """
end

function is_kwcall(signature::DataType)
    @static if VERSION < v"1.9"
        try
            return length(signature.parameters) >= 3 &&
                   signature <: Tuple{Function,Any,Any,Vararg} &&
                   (
                       signature.parameters[3] <: Type ||
                       isconcretetype(signature.parameters[3])
                   ) &&
                   signature.parameters[1] === Core.kwftype(signature.parameters[3])
        catch err
            @warn "Please open an issue on JuliaTesting/Aqua.jl for \"is_kwcall\" and the following data:" signature err
            return false
        end
    else
        return signature.parameters[1] === typeof(Core.kwcall)
    end
end
