"""
    test_ambiguities(package::Union{Module, PkgId})
    test_ambiguities(packages::Vector{Union{Module, PkgId}})

Test that there is no method ambiguities in given package(s).  It
calls `Test.detect_ambiguities` in a separated clean process to avoid
false-positive.
"""
test_ambiguities(packages; kwargs...) =
    _test_ambiguities(aspkgids(packages); kwargs...)

aspkgids(pkg::Union{Module, PkgId}) = aspkgids([pkg])
aspkgids(packages) = mapfoldl(aspkgid, push!, packages, init=PkgId[])

aspkgid(pkg::PkgId) = pkg
function aspkgid(m::Module)
    if !ispackage(m)
        error("Non-package (non-toplevel) module is not supported.",
              " Got: $m")
    end
    return PkgId(m)
end
function aspkgid(name::Symbol)
    # Maybe `Base.depwarn()`
    return Base.identify_package(String(name)) :: PkgId
end

ispackage(m::Module) =
    if m === Base
        true
    else
        parentmodule(m) == m
    end

strnameof(x) = string(x)
strnameof(x::Type) = string(nameof(x))

normalize_exclude(x::String) = x
normalize_exclude(x::Union{Type, Function}) =
    join((fullname(parentmodule(x))..., strnameof(x)), ".")
normalize_exclude(::Any) =
    error("Only a function and type can be excluded.")

function getobj(spec::String, modules)
    nameparts = Symbol.(split(spec, "."))
    for m in modules
        if nameparts[1] === nameof(m)
            return foldl(getproperty, nameparts[2:end], init=m)
        end
    end
    error("Object $spec not found in following modules:\n$modules")
end

function normalize_and_check_exclude(exclude::AbstractVector, packages)
    strexclude = mapfoldl(normalize_exclude, push!, exclude, init=String[])
    modules = map(Base.require, packages)
    for (str, obj) in zip(strexclude, exclude)
        obj isa String && continue
        if getobj(str, modules) !== obj
            error("Name `$str` is resolved to a different object.")
        end
    end
    return strexclude :: Vector{String}
end

function _test_ambiguities(
    packages::Vector{PkgId};
    color::Union{Bool, Nothing} = nothing,
    exclude::AbstractArray = [],
    # Options to be passed to `Test.detect_ambiguities`:
    recursive::Bool = true,
    imported::Bool = false,
    ambiguous_bottom::Bool = false,
)
    packages_repr = reprpkgids(collect(packages))
    options_repr = repr((
        recursive = recursive,
        imported = imported,
        ambiguous_bottom = ambiguous_bottom,
    ))
    exclude_repr = repr(normalize_and_check_exclude(exclude, packages))

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
    @test success(pipeline(cmd; stdout=stdout, stderr=stderr))
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

getobj(m::Method) = getproperty(m.module, m.name)

function test_ambiguities_impl(
    packages::Vector{PkgId},
    options::NamedTuple,
    exclude::Vector{String},
)
    modules = map(Base.require, packages)
    @debug "Testing method ambiguities" modules
    ambiguities = detect_ambiguities(modules...; options...)

    if !isempty(exclude)
        exclude_objs = getobj.(exclude, Ref(modules))
        ambiguities = filter(ambiguities) do (m1, m2)
            # `getobj(m1) == getobj(m2)` so no need to check `m2`
            getobj(m1) ∉ exclude_objs
        end
    end

    if !isempty(ambiguities)
        printstyled("$(length(ambiguities)) ambiguities found", color=:red)
        println()
    end
    for (i, (m1, m2)) in enumerate(ambiguities)
        println("Ambiguity #", i)
        println(m1)
        println(m2)
        println()
    end
    return ambiguities == []
end
