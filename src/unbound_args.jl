"""
    test_unbound_args(module::Module)

Test that all methods in `module` and its submodules do not have
unbound type parameter.
"""
function test_unbound_args(m::Module)
    unbounds = detect_unbound_args_recursively(m)
    if !isempty(unbounds)
        @warn (
            "Unbound type parameters detected. This can occur for seemingly well-defined " *
            "parameters for specific subtypes of the type, in particular, types with `Vararg`. " *
            "For example, in `f(xs::Vararg{T}) where T = T`, `T` is undefined for `f()`, " *
            "where there are zero instances of `T` to define its type."
        )
        println("Methods with unbound type parameters:")
        for method in unbounds
            print(stderr, '\t')
            show(stderr, method)
            println(stderr)
        end
    end
    @test isempty(unbounds)
end

# There used to be a bug in `Test.detect_unbound_args` when used on
# a top-level module together with `recursive = true`, see
# <https://github.com/JuliaLang/julia/pull/31972>. This was fixed
# some time between 1.4.2 and 1.5.4, but for older versions we
# define `detect_unbound_args_recursively` with a workaround.
@static if VERSION < v"1.5.4"
    function detect_unbound_args_recursively(m)
        methods = []
        walkmodules(m) do x
            append!(methods, detect_unbound_args(x))
        end
        return methods
    end
else
    detect_unbound_args_recursively(m) = Test.detect_unbound_args(m; recursive = true)
end
