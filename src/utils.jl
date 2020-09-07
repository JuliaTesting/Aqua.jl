if !@isdefined(isnothing)
    isnothing(x) = x === nothing
end

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


module _TempModule
end

eval_string(code::AbstractString) = include_string(_TempModule, code)

function checked_repr(obj)
    code = repr(obj)
    if !isequal(eval_string(code), obj)
        error("`$repr` is not `repr`-safe")
    end
    return code
end

const stdlibs = try
    Pkg.Types.stdlibs
catch
    try
        # https://github.com/JuliaLang/Pkg.jl/pull/1559
        Pkg.Types.stdlib  # julia < 1.4
    catch
        # https://github.com/JuliaLang/Pkg.jl/pull/696
        Pkg.Types.gather_stdlib_uuids  # julia < 1.1
    end
end
