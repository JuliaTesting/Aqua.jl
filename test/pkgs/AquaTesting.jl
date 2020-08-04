module AquaTesting

using Base: PkgId, UUID
using Pkg
using Test

# Taken from Test/test/runtests.jl
mutable struct NoThrowTestSet <: Test.AbstractTestSet
    results::Vector
    NoThrowTestSet(desc) = new([])
end
Test.record(ts::NoThrowTestSet, t::Test.Result) = (push!(ts.results, t); t)
Test.finish(ts::NoThrowTestSet) = ts.results


macro testtestset(args...)
    @gensym TestSet
    expr = quote
        $TestSet = $NoThrowTestSet
        $Test.@testset($TestSet, $(args...))
    end
    esc(expr)
end


const SAMPLE_PKGIDS = [
    PkgId(UUID("1649c42c-2196-4c52-9963-79822cd6227b"), "PkgWithIncompatibleTestProject"),
    PkgId(UUID("6e4a843a-fdff-4fa3-bb5a-e4ae67826963"), "PkgWithCompatibleTestProject"),
    PkgId(UUID("7231ce0e-e308-4079-b49f-19e33cc3ac6e"), "PkgWithPostJulia12Support"),
    PkgId(UUID("8981f3dd-97fd-4684-8ec7-7b0c42f64e2e"), "PkgWithoutTestProject"),
    PkgId(nothing, "PkgWithoutProject"),
]

const SAMPLE_PKG_BY_NAME = Dict(pkg.name => pkg for pkg in SAMPLE_PKGIDS)

function with_sample_pkgs(f)
    sampledir = joinpath(@__DIR__, "sample")

    original_load_path = copy(LOAD_PATH)
    try
        pushfirst!(LOAD_PATH, sampledir)
        f()
    finally
        append!(empty!(LOAD_PATH), original_load_path)
    end
end

end  # module
