module TestUndocumentedNames

include("preamble.jl")

import PkgWithUndocumentedNames
import PkgWithUndocumentedNamesInSubmodule
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
println("### Expected output START ###")
results = @testtestset begin
    Aqua.test_undocumented_names(PkgWithUndocumentedNames)
end
println("### Expected output END ###")
if VERSION >= v"1.11"
    @test length(results) == 1
    @test results[1] isa Test.Fail
else
    @test length(results) == 0
end

println("### Expected output START ###")
results = @testtestset begin
    Aqua.test_undocumented_names(PkgWithUndocumentedNamesInSubmodule)
end
println("### Expected output END ###")
if VERSION >= v"1.11"
    @test length(results) == 1
    @test results[1] isa Test.Fail
else
    @test length(results) == 0
end

# Broken
println("### Expected output START ###")
results = @testtestset begin
    Aqua.test_undocumented_names(PkgWithUndocumentedNames; broken = true)
end
println("### Expected output END ###")
if VERSION >= v"1.11"
    @test length(results) == 1
    @test results[1] isa Test.Broken
else
    @test length(results) == 0
end

end  # module
