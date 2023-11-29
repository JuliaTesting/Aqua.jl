# Compat entries

In your `Project.toml` you can (and should) use compat entries to specify
with which versions of Julia and your dependencies your package is compatible with.
This is important to ease the installation and upgrade of your package for users,
and to keep everything working in the case of breaking changes in Julia or your dependencies.

For more details, see the [Pkg docs](https://julialang.github.io/Pkg.jl/v1/compatibility/).

## [Test function](@id test_deps_compat)

```@docs
Aqua.test_deps_compat
```
