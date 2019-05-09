module TestAqua

using Test

@testset "$path" for path in [
    "test_smoke.jl"
]
    include(path)
end

end  # module
