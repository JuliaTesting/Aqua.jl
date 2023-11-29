# Unbound Type Parameters

An unbound type parameter is a type parameter with a `where`,
that does not occur in the signature of some dispatch of the method.

## Examples

The following methods each have `T` as an unbound type parameter:

```@repl
f(x::Int) where {T} = do_something(x)
g(x::T...) where {T} = println(T)
```

In the cases of `f` above, the unbound type parameter `T` is neither
present in the signature of the methods nor as a bound of another type parameter.
Here, the type parameter `T` can be removed without changing any semantics.

For signatures with `Vararg` (cf. `g` above), the type parameter is unbound for the 
zero-argument case (e.g. `g()`).

```@repl
g(1.0, 2.0)
g(1)
g()
```

A possible fix would be to replace `g` by two methods.

```@repl
g() = println(Int)  # Defaults to `Int`
g(x1::T, x2::T...) where {T} = println(T)
g(1.0, 2.0)
g(1)
g()
```

## [Test function](@id test_unbound_args)

```@docs
Aqua.test_unbound_args
```
