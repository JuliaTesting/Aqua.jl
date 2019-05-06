function test_ambiguities(packages)
    packages = map(Symbol, packages) :: Vector{Symbol}
    packages_repr = repr(packages)
    @assert Base.eval(Main, Meta.parse(packages_repr)) == packages

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

load_package(m::Module) = m
load_package(name::Union{Symbol, AbstractString}) =
    Base.require(Base.identify_package(String(name)))

function test_ambiguities_impl(packages)
    modules = map(load_package, packages)
    @debug "Testing method ambiguities" modules
    ambiguities = detect_ambiguities(modules...; recursive=true)
    @test ambiguities == []
end
