module TestUndocumentedNames

include("preamble.jl")

import PkgWithUndocumentedNames
import PkgWithoutUndocumentedNames

# Pass
results = @testtestset begin
    Aqua.test_undocumented_names(PkgWithoutUndocumentedNames)
end
if VERSION >= v"1.11"
    @test length(results) == 1
    @test results[1] isa Test.Pass
else
    @test length(results) == 0
end
# Fail
results = @testtestset begin
    Aqua.test_undocumented_names(PkgWithUndocumentedNames)
end
if VERSION >= v"1.11"
    @test length(results) == 1
    @test results[1] isa Test.Fail
else
    @test length(results) == 0
end

end  # module
