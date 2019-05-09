module AquaTesting

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

end  # module
