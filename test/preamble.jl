let path = joinpath(@__DIR__, "pkgs")
    if path ∉ LOAD_PATH
        pushfirst!(LOAD_PATH, path)
    end
end

using Test
using Aqua
using AquaTesting: @testtestset, AquaTesting, with_sample_pkgs
