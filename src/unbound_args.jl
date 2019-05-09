"""
    test_unbound_args(module::Module)

Test that all methods in `module` and its submodules do not have
unbound type parameter.
"""
function test_unbound_args(m::Module)
    # https://github.com/JuliaLang/julia/pull/31972
    # @test detect_unbound_args(m; recursive=true) == []
    @test detect_unbound_args_recursively(m) == []
end

function detect_unbound_args_recursively(m)
    methods = []
    walkmodules(m) do x
        append!(methods, detect_unbound_args(x))
    end
    return methods
end
