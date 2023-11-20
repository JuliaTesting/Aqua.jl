# Unbound Type Parameters

An unbound type parameter is a type parameter with a `where`,
that does not occur in the signature of some dispatch of the method.

## Examples

The following methods each have `T` as an unbound type parameter:

```julia
f(x::Int) where {T} = do_something(x)

g(x::S) where {S < : Number, T <: Number} = do_something(x)

h(x::T...) where {T} = do_something(x)
```

In the cases of `f` and `g` above, the unbound type parameter `T` is neither
present in the signature of the methods nor as a bound of another type parameter.
Here, the type parameter `T` can be removed without changing any semantics.

For signatures with `Vararg` (cf. `h` above), the type parameter is unbound for the 
zero-argument case (e.g. `h()`). A possible fix would be to replace `h` by two
methods
```julia
h() = do_something(T[])
h(x1::T, x2::T...) = do_something(T[x1, x2...])
```

## [Test function](@id test_unbound_args)

```@docs
Aqua.test_unbound_args
```
