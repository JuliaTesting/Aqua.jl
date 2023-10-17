"""
    test_unbound_args(module::Module)

Test that all methods in `module` and its submodules do not have
unbound type parameters. An unbound type parameter is a type parameter
with a `where`, that does not occur in the signature of some dispatch
of the method.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test`.

For example, the following methods each have `T` as an unbound type parameter:

```julia
f(x::Int) where {T} = do_something(x)

g(x::S) where {S < : Number, T <: Number} = do_something(x)

h(x::T...) where {T} = do_something(x)
```

In the cases of `f` and `g` above, the unbound type parameter `T` is neither
present in the signature of the methods nor as a bound of another type parameter.
Here, the type parameter `T` can be removed without changing any semantics.

For signatures with `Vararg` (cf. `h` above), the type parameter unbound for the 
zero-argument case (e.g. `h()`). A possible fix would be to replace `h` by two
methods
```julia
h() = do_something(T[])
h(x1::T, x2::T...) = do_something(T[x1, x2...])
```
"""
function test_unbound_args(m::Module; broken::Bool = false)
    unbounds = detect_unbound_args_recursively(m)
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
    if broken
        @test_broken isempty(unbounds)
    else
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
