# Aqua.jl:
## *A*uto *QU*ality *A*ssurance for Julia packages

Aqua.jl provides functions to run a few automatable checks for Julia packages:

* There are no method ambiguities.
* There are no undefined `export`s.
* There are no unbound type parameters.
* There are no stale dependencies listed in `Project.toml`.
* Check that test target of the root project `Project.toml` and test project (`test/Project.toml`) are consistent.
* Check that all external packages listed in `deps` have corresponding `compat` entries.
* There are no "obvious" type piracies.
* The package does not create any persistent Tasks that might block precompilation of dependencies.

## Quick usage

Call `Aqua.test_all(YourPackage)` from the REPL, e.g.,

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
    Aqua = "0.8"
    ```

 2. In `YourPackage/Project.toml`, add Aqua.jl to `[compat]` and `[extras]` section and the `test` target, like
    ```toml
    [compat]
    Aqua = "0.8"

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
    stale_deps=(ignore=[:SomePackage],),
    deps_compat=(ignore=[:SomeOtherPackage],),
    piracies=false,
  )
end
```
Note, that for all tests with no explicit options provided, the default options are used.

For more details on the options, see the respective functions [below](@ref test_functions).

### Example uses
The following is a small selection of packages that use Aqua.jl:
- [GAP.jl](https://github.com/oscar-system/GAP.jl)
- [Hecke.jl](https://github.com/thofma/Hecke.jl)
- [Oscar.jl](https://github.com/oscar-system/Oscar.jl)

## [Test functions](@id test_functions)
```@docs
Aqua.test_all
```

```@autodocs
Modules = [Aqua]
Filter = t -> (startswith(String(nameof(t)), "test_") && t != Aqua.test_all) || t == Aqua.find_persistent_tasks_deps
```
