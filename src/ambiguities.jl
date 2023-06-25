"""
    test_ambiguities(package::Union{Module, PkgId})
    test_ambiguities(packages::Vector{Union{Module, PkgId}})

Test that there is no method ambiguities in given package(s).  It
calls `Test.detect_ambiguities` in a separated clean process to avoid
false-positive.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test`.
- `color::Union{Bool, Nothing} = nothing`: Enable/disable colorful
  output if a `Bool`.  `nothing` (default) means to inherit the
  setting in the current process.
- `exclude::AbstractVector = []`: A vector of functions or types to be
  excluded from ambiguity testing.  A function means to exclude _all_
  its methods.  A type means to exclude _all_ its methods of the
  callable (sometimes also called "functor") and the constructor.  
  That is to say, `MyModule.MyType` means to ignore ambiguities between 
  `(::MyType)(x, y::Int)` and `(::MyType)(x::Int, y)`.
- `recursive::Bool = true`: Passed to `Test.detect_ambiguities`.
  Note that the default here (`true`) is different from
  `detect_ambiguities`.  This is for testing ambiguities in methods
  defined in all sub-modules.
- Other keyword arguments such as `imported` and `ambiguous_bottom`
  are passed to `Test.detect_ambiguities` as-is.
"""
test_ambiguities(packages; kwargs...) = _test_ambiguities(aspkgids(packages); kwargs...)

const ExcludeSpec = Pair{Base.PkgId,String}

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

strnameof(x) = string(x)
strnameof(x::Type) = string(nameof(x))

rootmodule(x) = rootmodule(parentmodule(x))
rootmodule(m::Module) = Base.require(PkgId(m))  # this handles Base/Core well

normalize_exclude(x::Union{Type,Function}) =
    Base.PkgId(rootmodule(x)) => join((fullname(parentmodule(x))..., strnameof(x)), ".")
normalize_exclude(::Any) = error("Only a function and type can be excluded.")

function getobj((pkgid, name)::ExcludeSpec)
    nameparts = Symbol.(split(name, "."))
    m = Base.require(pkgid)
    return foldl(getproperty, nameparts, init = m)
end

function normalize_and_check_exclude(exclude::AbstractVector)
    exspecs = mapfoldl(normalize_exclude, push!, exclude, init = ExcludeSpec[])
    for (spec, obj) in zip(exspecs, exclude)
        if getobj(spec) !== obj
            error("Name `$(spec[2])` is resolved to a different object.")
        end
    end
    return exspecs::Vector{ExcludeSpec}
end

function reprexclude(exspecs::Vector{ExcludeSpec})
    itemreprs = map(exspecs) do (pkgid, name)
        string("(", reprpkgid(pkgid), " => ", repr(name), ")")
    end
    return string("Aqua.ExcludeSpec[", join(itemreprs, ", "), "]")
end

function _test_ambiguities(packages::Vector{PkgId}; broken::Bool = false, kwargs...)
    num_ambiguities, strout, strerr = _find_ambiguities(packages; kwargs...)

    println(stderr, strerr)
    println(stdout, strout)

    if broken
        @test_broken num_ambiguities == 0
    else
        @test num_ambiguities == 0
    end
end

function _find_ambiguities(
    packages::Vector{PkgId};
    color::Union{Bool,Nothing} = nothing,
    exclude::AbstractVector = [],
    # Options to be passed to `Test.detect_ambiguities`:
    detect_ambiguities_options...,
)
    packages_repr = reprpkgids(collect(packages))
    options_repr = checked_repr((; recursive = true, detect_ambiguities_options...))
    exclude_repr = reprexclude(normalize_and_check_exclude(exclude))

    # Ambiguity test is run inside a clean process.
    # https://github.com/JuliaLang/julia/issues/28804
    code = """
    $(Base.load_path_setup_code())
    using Aqua
    Aqua.test_ambiguities_impl(
        $packages_repr,
        $options_repr,
        $exclude_repr,
    ) || exit(1)
    """
    cmd = Base.julia_cmd()
    if something(color, Base.JLOptions().color == 1)
        cmd = `$cmd --color=yes`
    end
    cmd = `$cmd --startup-file=no -e $code`

    out = Pipe()
    err = Pipe()
    succ = success(pipeline(cmd; stdout = out, stderr = err))
    close(out.in)
    close(err.in)
    strout = String(read(out))
    strerr = String(read(err))
    num_ambiguities = if succ
        0
    else
        parse(Int, match(r"(\d+) ambiguities found", strout).captures[1])
    end

    return num_ambiguities, strout, strerr
end

function reprpkgids(packages::Vector{PkgId})
    packages_repr = sprint() do io
        println(io, '[')
        for pkg in packages
            println(io, reprpkgid(pkg))
        end
        println(io, ']')
    end
    @assert Base.eval(Main, Meta.parse(packages_repr)) == packages
    return packages_repr
end

function reprpkgid(pkg::PkgId)
    name = pkg.name
    if pkg.uuid === nothing
        return "Base.PkgId($(repr(name)))"
    end
    uuid = pkg.uuid.value
    return "Base.PkgId(Base.UUID($(repr(uuid))), $(repr(name)))"
end

struct _NoValue end

function getobj(m::Method)
    ty = try
        fieldtype(m.sig, 1)
    catch err
        @error(
            "Failed to obtain a function from `Method`.",
            exception = (err, catch_backtrace())
        )
        # If this doesn't work, `Base` internal was probably changed
        # too much compared to what it is now.  So, bailing out.
        return _NoValue()
    end
    ty = Base.unwrap_unionall(ty)
    if ty <: Function
        try
            return ty.instance  # this should work for functions
        catch
        end
    end
    try
        if ty.name.wrapper === Type
            return ty.parameters[1]
        else
            return ty.name.wrapper
        end
    catch err
        @error(
            "Failed to obtain a function from `Method`.",
            exception = (err, catch_backtrace())
        )
    end
    return _NoValue()
end

function test_ambiguities_impl(
    packages::Vector{PkgId},
    options::NamedTuple,
    exspecs::Vector{ExcludeSpec},
)
    modules = map(Base.require, packages)
    @debug "Testing method ambiguities" modules
    ambiguities = detect_ambiguities(modules...; options...)

    if !isempty(exspecs)
        exclude_objs = getobj.(exspecs)
        ambiguities = filter(ambiguities) do (m1, m2)
            getobj(m1) ∉ exclude_objs && getobj(m2) ∉ exclude_objs
        end
    end

    if !isempty(ambiguities)
        printstyled("$(length(ambiguities)) ambiguities found", color = :red)
        println()
    end
    for (i, (m1, m2)) in enumerate(ambiguities)
        println("Ambiguity #", i)
        println(m1)
        println(m2)
        @static if isdefined(Base, :morespecific)
            ambiguity_hint(m1, m2)
            println()
        end
        println()
    end
    return ambiguities == []
end

function ambiguity_hint(m1::Method, m2::Method)
    # based on base/errorshow.jl#showerror_ambiguous
    # https://github.com/JuliaLang/julia/blob/v1.7.2/base/errorshow.jl#L327-L353
    sigfix = Any
    sigfix = typeintersect(m1.sig, sigfix)
    sigfix = typeintersect(m2.sig, sigfix)
    if isa(Base.unwrap_unionall(sigfix), DataType) && sigfix <: Tuple
        let sigfix = sigfix
            if all(m -> Base.morespecific(sigfix, m.sig), [m1, m2])
                print("\nPossible fix, define\n  ")
                Base.show_tuple_as_call(stdout, :function, sigfix)
            else
                println()
                print(
                    """To resolve the ambiguity, try making one of the methods more specific, or 
                    adding a new method more specific than any of the existing applicable methods.""",
                )
            end
        end
    end
end
