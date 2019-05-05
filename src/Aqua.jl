module Aqua

using Test

load_package(m::Module) = m
load_package(name::Union{Symbol, AbstractString}) =
    Base.require(Base.identify_package(String(name)))

function test_ambiguities_impl(packages)
    modules = map(load_package, packages)
    @debug "Testing method ambiguities" modules
    ambiguities = detect_ambiguities(modules...; recursive=true)
    @test ambiguities == []
end

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

function walkmodules(f, x::Module)
    f(x)
    for n in names(x)
        if isdefined(x, n)
            y = getproperty(x, n)
            if y isa Module && y !== x && parentmodule(y) === x
                walkmodules(f, y)
            end
        end
    end
end

"""
    undefined_exports(m::Module) :: Vector{Symbol}
"""
function undefined_exports(m::Module)
    undefined = Symbol[]
    walkmodules(m) do x
        for n in names(x)
            isdefined(x, n) || push!(undefined, n)
        end
    end
    return undefined
end

"""
    autoqa(testtarget::Module)
"""
function autoqa(testtarget::Module)
    @testset "Method ambiguity" begin
        test_ambiguities([nameof(testtarget)])
    end
    @testset "Undefined exports" begin
        @test undefined_exports(testtarget) == []
    end
end

end # module
