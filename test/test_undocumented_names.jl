module TestUndocumentedNames

include("preamble.jl")

import PkgWithUndocumentedNames
import PkgWithoutUndocumentedNames

@testset begin
    # Pass
    results = @testtestset begin
        Aqua.test_undocumented_names(PkgWithoutUndocumentedNames)
    end
    @test length(results) == 1
    @test results[1] isa Test.Pass
    # Fail
    results = @testtestset begin
        Aqua.test_undocumented_names(PkgWithUndocumentedNames)
    end
    @test length(results) == 1
    @test results[1] isa (VERSION >= v"1.11" ? Test.Fail : Test.Pass)
    # Logs
    @test_nowarn Aqua.test_undocumented_names(PkgWithoutUndocumentedNames)
end

end  # module
