# Ambiguities

Method ambiguities are cases where multiple methods are applicable to a given set of arguments, without having a most specific method.

## Examples
One easy example is the following:
```@example
f(x::Int, y::Integer) = 1
f(x::Integer, y::Int) = 2

println(f(1, 2))
```
This will throw an `MethodError` because both methods are equally specific. The solution is to add a third method:
```julia
f(x::Int, y::Int) = ? # `?` is dependent on the use case, most times it will be `1` or `2`
```

## [Test function](@id test_ambiguities)

```@docs
Aqua.test_ambiguities
```
