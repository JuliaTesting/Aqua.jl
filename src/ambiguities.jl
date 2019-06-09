"""
    test_ambiguities(package::Union{Module, PkgId})
    test_ambiguities(packages::Vector{Union{Module, PkgId}})

Test that there is no method ambiguities in given package(s).  It
calls `Test.detect_ambiguities` in a separated clean process to avoid
false-positive.
"""
test_ambiguities(packages) = _test_ambiguities(aspkgids(packages))

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

function _test_ambiguities(packages::Vector{PkgId})
    packages_repr = reprpkgids(collect(packages))

    # Ambiguity test is run inside a clean process.
    # https://github.com/JuliaLang/julia/issues/28804
    code = """
    $(Base.load_path_setup_code())
    using Aqua
    Aqua.test_ambiguities_impl($packages_repr)
    """
    cmd = Base.julia_cmd()
    if Base.JLOptions().color == 1
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

function test_ambiguities_impl(packages::Vector{PkgId})
    modules = map(Base.require, packages)
    @debug "Testing method ambiguities" modules
    ambiguities = detect_ambiguities(modules...; recursive=true)
    @test ambiguities == []
end
