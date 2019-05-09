module TestAqua

using Test

@testset "$path" for path in [
    "test_smoke.jl"
    "test_ambiguities.jl"
    "test_undefined_exports.jl"
]
    include(path)
end

end  # module
