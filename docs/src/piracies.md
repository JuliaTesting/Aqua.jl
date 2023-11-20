# Type piracy

Type piracy is a term used to describe adding methods to a foreign function
with only foreign arguments.
This is considered bad practice because it can cause unexpected behavior
when the function is called, in particular, it can change the behavior of
one of your dependencies depending on if your package is loaded or not.
This makes it hard to reason about the behavior of your code, and may
introduce bugs that are hard to track down.

See [Julia documentation](https://docs.julialang.org/en/v1/manual/style-guide/#Avoid-type-piracy) for more information about type piracy.

## Examples

Say that `PkgA` is foreign, and let's look at the different ways that `PkgB` extends its function `bar`.

```julia
module PkgA
    struct C end
    bar(x::C) = 42
    bar(x::Vector) = 43
end

module PkgB 
    import PkgA: bar, C
    struct D end
    bar(x::C) = 1
    bar(xs::D...) = 2
    bar(x::Vector{<:D}) = 3
    bar(x::Vector{D}) = 4 # slightly bad (may cause invalidations)
    bar(x::Union{C,D}) = 5 # slightly bad (a change in PkgA may turn it into piracy)
    #                        (for example changing bar(x::C) = 1 to bar(x::Union{C,Int}) = 1)
end
```

The following cases are enumerated by the return values in the example above:
1. This is the worst case of type piracy. The value of `bar(C())` can be
   either `1` or `42` and will depend on whether `PkgB` is loaded or not.
2. This is also a bad case of type piracy. `bar()` throws a `MethodError` with
   only `PkgA` available, and returns `2` with `PkgB` loaded. `PkgA` may add
   a method for `bar()` that takes no arguments in the future, and then this
   is equivalent to case 1.
3. This is a moderately bad case of type piracy. `bar(Union{}[])` returns `3`
   when `PkgB` is loaded, and `43` when `PkgB` is not loaded, although neither
   of the occurring types are defined in `PkgB`. This case is not as bad as
   cases 1 and 2, because it is only about behavior around `Union{}`, which has
   no instances.
4. Depending on ones understanding of type piracy, this could be considered piracy
   as well. In particular, this may cause invalidations.
5. This is a slightly bad case of type piracy. In the current form, `bar(C())`
   returns `42` as the dispatch on `Union{C,D}` is less specific. However, a
   future change in `PkgA` may change this behavior, e.g. by changing `bar(x::C)`
   to `bar(x::Union{C,Int})` the call `bar(C())` would become ambiguous.

!!! note
    The test function below currently only checks for cases 1 and 2.

## [Test function](@id test_piracies)

```@docs
Aqua.test_piracies
```
