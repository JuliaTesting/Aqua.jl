module TestAqua

using Test

@testset verbose = true "Aqua" begin
    @testset "$file" for file in sort([
        file for file in readdir(@__DIR__) if match(r"^test_.*\.jl$", file) !== nothing
    ])
        include(file)
    end
end

end  # module
