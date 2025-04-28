"""
    test_ambiguities(package::Union{Module, PkgId})
    test_ambiguities(packages::Vector{Union{Module, PkgId}})

Test that there is no method ambiguities in given package(s).  It
calls `Test.detect_ambiguities` in a separated clean process to avoid
false-positives.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test` and shortens the error message.
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
    for name in nameparts
        m = getproperty(m, name)
    end
    return m
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
    num_ambiguities, strout, strerr =
        _find_ambiguities(packages; skipdetails = broken, kwargs...)

    print(stderr, strerr)
    print(stdout, strout)

    if broken
        @test_broken iszero(num_ambiguities)
    else
        @test iszero(num_ambiguities)
    end
end

function _find_ambiguities(
    packages::Vector{PkgId};
    skipdetails::Bool = false,
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
        $skipdetails,
    ) || exit(1)
    """
    cmd = Base.julia_cmd()
    if something(color, Base.JLOptions().color == 1)
        cmd = `$cmd --color=yes`
    end
    cmd = `$cmd --startup-file=no -e $code`

    mktemp() do outfile, out
        mktemp() do errfile, err
            succ = success(pipeline(cmd; stdout = out, stderr = err))
            strout = read(outfile, String)
            strerr = read(errfile, String)
            num_ambiguities = if succ
                0
            else
                reg_match = match(r"(\d+) ambiguities found", strerr)

                reg_match === nothing && error(
                    "Failed to parse output of `detect_ambiguities`.\nThe stdout was:\n" *
                    strout *
                    "\n\nThe stderr was:\n" *
                    strerr,
                )

                parse(Int, reg_match.captures[1]::AbstractString)
            end
            return num_ambiguities, strout, strerr
        end
    end
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
    uuid = pkg.uuid
    if uuid === nothing
        return "Base.PkgId($(repr(name)))"
    end
    return "Base.PkgId(Base.UUID($(repr(uuid.value))), $(repr(name)))"
end

function test_ambiguities_impl(
    packages::Vector{PkgId},
    options::NamedTuple,
    exspecs::Vector{ExcludeSpec},
    skipdetails::Bool,
)
    modules = map(Base.require, packages)
    @debug "Testing method ambiguities" modules
    ambiguities = detect_ambiguities(modules...; options...)

    if !isempty(exspecs)
        exclude_ft = Any[getobj(spec) for spec in exspecs]
        exclude_sig = Any[]
        for ft in exclude_ft
            if ft isa Type
                push!(exclude_sig, Tuple{ft, Vararg})
                push!(exclude_sig, Tuple{Core.kwftype(ft), Any, ft, Vararg})
                ft = Type{<:ft} # alternatively, Type{ft}
            else
                ft = typeof(ft)
            end
            push!(exclude_sig, Tuple{ft, Vararg})
            push!(exclude_sig, Tuple{Core.kwftype(ft), Any, ft, Vararg})
        end
        ambiguities = filter(ambiguities) do (m1, m2)
            for excl in exclude_sig
                if m1.sig <: excl || m2.sig <: excl
                    return false
                end
            end
            return true
        end
    end

    sort!(ambiguities, by = (ms -> (ms[1].name, ms[2].name)))

    if !isempty(ambiguities)
        printstyled(
            stderr,
            "$(length(ambiguities)) ambiguities found. To get a list, set `broken = false`.\n";
            bold = true,
            color = Base.error_color(),
        )
    end
    if !skipdetails
        for (i, (m1, m2)) in enumerate(ambiguities)
            println(stderr, "Ambiguity #", i)
            println(stderr, m1)
            println(stderr, m2)
            @static if isdefined(Base, :morespecific)
                ambiguity_hint(stderr, m1, m2)
                println(stderr)
            end
            println(stderr)
        end
    end
    return isempty(ambiguities)
end

function ambiguity_hint(io::IO, m1::Method, m2::Method)
    # based on base/errorshow.jl#showerror_ambiguous
    # https://github.com/JuliaLang/julia/blob/v1.7.2/base/errorshow.jl#L327-L353
    sigfix = Any
    sigfix = typeintersect(m1.sig, sigfix)
    sigfix = typeintersect(m2.sig, sigfix)
    if isa(Base.unwrap_unionall(sigfix), DataType) && sigfix <: Tuple
        let sigfix = sigfix
            if all(m -> Base.morespecific(sigfix, m.sig), [m1, m2])
                print(io, "\nPossible fix, define\n  ")
                Base.show_tuple_as_call(io, :function, sigfix)
            else
                println(io)
                print(
                    io,
                    """To resolve the ambiguity, try making one of the methods more specific, or 
                    adding a new method more specific than any of the existing applicable methods.""",
                )
            end
        end
    end
end
