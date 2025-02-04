"""
    test_unbound_args(module::Module)

Test that all methods in `module` and its submodules do not have
unbound type parameters. An unbound type parameter is a type parameter
with a `where`, that does not occur in the signature of some dispatch
of the method.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test` and shortens the error message.
- `exclude::AbstractVector = []`: A vector of signatures of methods to exclude
  from testing. A signature is usually of the form `Tuple{typeof(f), T1, T2, ...}`.
  where `f` is the function and `T1, T2, ...` the type parameters. For example, the
  signature of `f(x::Float64, y)` is `Tuple{typeof(f), Float64, Any}`.
"""
function test_unbound_args(m::Module; broken::Bool = false, exclude = [])
    unbounds = detect_unbound_args_recursively(m)
    for signature in exclude
        filter!(method -> (method.sig != signature), unbounds)
    end

    if broken
        if !isempty(unbounds)
            printstyled(
                stderr,
                "$(length(unbounds)) instances of unbound type parameters detected. To get a list, set `broken = false`.\n";
                bold = true,
                color = Base.error_color(),
            )
        end
        @test_broken isempty(unbounds)
    else
        if !isempty(unbounds)
            printstyled(
                stderr,
                "Unbound type parameters detected:\n";
                bold = true,
                color = Base.error_color(),
            )
            show(stderr, MIME"text/plain"(), unbounds)
            println(stderr)
        end

        @test isempty(unbounds)
    end
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
