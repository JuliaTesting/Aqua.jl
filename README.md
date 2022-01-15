# Aqua.jl: *A*uto *QU*ality *A*ssurance for Julia packages

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliatesting.github.io/Aqua.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliatesting.github.io/Aqua.jl/dev)
[![GitHub Actions](https://github.com/JuliaTesting/Aqua.jl/workflows/Run%20tests/badge.svg)](https://github.com/JuliaTesting/Aqua.jl/actions?query=workflow%3ARun+tests)
[![Codecov](https://codecov.io/gh/JuliaTesting/Aqua.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaTesting/Aqua.jl)
[![GitHub commits since tagged version](https://img.shields.io/github/commits-since/JuliaTesting/Aqua.jl/v0.5.2.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Aqua QA](./badge.png)](https://github.com/JuliaTesting/Aqua.jl)

Aqua.jl provides functions to run a few automatable checks for Julia packages:

* There are no method ambiguities.
* There are no undefined `export`s.
* There are no unbound type parameters.
* There are no stale dependencies listed in `Project.toml`.
* Check that test target of the root project `Project.toml` and test project
  (`test/Project.toml`) are consistent.
* Check that all external packages listed in `deps` have corresponding
  `compat` entry.
* `Project.toml` formatting is compatible with Pkg.jl output.

See more in the [documentation](https://juliatesting.github.io/Aqua.jl/dev).

## Quick usage

Call `Aqua.test_all(YourPackage)` from `test/runtests.jl`, e.g.,

```julia
using YourPackage
using Aqua
Aqua.test_all(YourPackage)
```

## Specifying Aqua version

To avoid breaking test when a new Aqua.jl version is released, it is
recommended to add version bound for Aqua.jl in `test/Project.toml`:

```toml
[deps]
Aqua = "4c88cf16-eb10-579e-8560-4a9242c79595"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[compat]
Aqua = "0.5"
```
