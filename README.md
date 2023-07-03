# Aqua.jl: *A*uto *QU*ality *A*ssurance for Julia packages

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliatesting.github.io/Aqua.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliatesting.github.io/Aqua.jl/dev)
[![GitHub Actions](https://github.com/JuliaTesting/Aqua.jl/workflows/Run%20tests/badge.svg)](https://github.com/JuliaTesting/Aqua.jl/actions?query=workflow%3ARun+tests)
[![Codecov](https://codecov.io/gh/JuliaTesting/Aqua.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaTesting/Aqua.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

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
* There are no "obvious" type piracies.

See more in the [documentation](https://juliatesting.github.io/Aqua.jl/dev).

## Quick usage

Call `Aqua.test_all(YourPackage)` from `test/runtests.jl`, e.g.,

```julia
using YourPackage
using Aqua
Aqua.test_all(YourPackage)
```

## How to add Aqua.jl...

### ...as a test dependency?

There are two ways to add Aqua.jl as a test dependency to your package.
To avoid breaking tests when a new Aqua.jl version is released, it is
recommended to add a version bound for Aqua.jl.

 1. In `YourPackage/test/Project.toml`, add Aqua.jl to `[dep]` and `[compat]` sections, like
    ```toml
    [deps]
    Aqua = "4c88cf16-eb10-579e-8560-4a9242c79595"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

    [compat]
    Aqua = "0.6"
    ```

 2. In `YourPackage/Project.toml`, add Aqua.jl to `[compat]` and `[extras]` section and the `test` target, like
    ```toml
    [compat]
    Aqua = "0.6"

    [extras]
    Aqua = "4c88cf16-eb10-579e-8560-4a9242c79595"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

    [targets]
    test = ["Aqua", "Test"]
    ```

If your package supports Julia pre-1.2, you need to use the second approach, 
although you can use both approaches at the same time.

!!! warning
    In normal use, `Aqua.jl` should not be added to `[deps]` in `YourPackage/Project.toml`!

### ...to your tests?
It is recommended to create a separate file `YourPackage/test/Aqua.jl` that gets included in `YourPackage/test/runtests.jl` 
with either

```julia
using Aqua
Aqua.test_all(YourPackage)
```
or some fine-grained checks with options, e.g.,

```julia
using Aqua

@testset "Aqua.jl" begin
  Aqua.test_all(
    YourPackage;
    ambiguities=(exclude=[SomePackage.some_function], broken=true),
    unbound_args=true,
    undefined_exports=true,
    project_extras=true,
    stale_deps=(ignore=[:SomePackage],),
    deps_compat=(ignore=[:SomeOtherPackage],),
    project_toml_formatting=true,
    piracy=false,
  )
end
```
For more details on the options, see the [documentation](https://juliatesting.github.io/Aqua.jl/dev).

### Example uses
The following is a small selection of packages that use Aqua.jl:
- [GAP.jl](https://github.com/oscar-system/GAP.jl)
- [Hecke.jl](https://github.com/thofma/Hecke.jl)
- [Oscar.jl](https://github.com/oscar-system/Oscar.jl)

## Badge

You can add the following line in README.md to include Aqua.jl badge:

```markdown
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
```

which is rendered as

> [![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
