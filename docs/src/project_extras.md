# Project.toml extras

There are two different ways to specify test-only dependencies (see [the Pkg docs](https://julialang.github.io/Pkg.jl/v1/creating-packages/#Test-specific-dependencies)):
1. Add the test-only dependencies to the `[extras]` section of your `Project.toml` file
   and use a test target.
2. Add the test-only dependencies to the `[deps]` section of your `test/Project.toml` file.
   This is only available in Julia 1.2 and later.

This test checks checks that, in case you use both methods, the set of test-only dependencies
is the same in both ways.

## [Test function](@id test_project_extras)

```@docs
Aqua.test_project_extras
```
