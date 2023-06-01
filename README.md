# Aqua.jl: *A*uto *QU*ality *A*ssurance for Julia packages

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliatesting.github.io/Aqua.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliatesting.github.io/Aqua.jl/dev)
[![GitHub Actions](https://github.com/JuliaTesting/Aqua.jl/workflows/Run%20tests/badge.svg)](https://github.com/JuliaTesting/Aqua.jl/actions?query=workflow%3ARun+tests)
[![Codecov](https://codecov.io/gh/JuliaTesting/Aqua.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaTesting/Aqua.jl)
[![GitHub commits since tagged version](https://img.shields.io/github/commits-since/JuliaTesting/Aqua.jl/v0.6.1.svg)](https://github.com/JuliaTesting/Aqua.jl)
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
* There are no "obvious" type piracies ([**new in 0.6**](#notes-on-aqua-06))

See more in the [documentation](https://juliatesting.github.io/Aqua.jl/dev).

## Quick usage

Call `Aqua.test_all(YourPackage)` from `test/runtests.jl`, e.g.,

```julia
using YourPackage
using Aqua
Aqua.test_all(YourPackage)
```

## Notes on Aqua 0.6

Aqua 0.6 includes the type piracy detection, thanks to [the PR](https://github.com/JuliaTesting/Aqua.jl/pull/88) by Jakob
Nybo Nissen (@jakobnissen) and [the original implementation](https://discourse.julialang.org/t/pirate-hunter/20402) by
Frames Catherine White (@oxinabox).

If this part of Aqua 0.6 causes a trouble, there are two ways to solve the issue:

1. Keep using Aqua 0.5.  It is still maintained.
2. Disable the piracy detection by the flag as in
   `Aqua.test_all(YourPackage; piracy = false)`.

## Specifying Aqua version

To avoid breaking test when a new Aqua.jl version is released, it is
recommended to add version bound for Aqua.jl in `test/Project.toml`:

```toml
[deps]
Aqua = "4c88cf16-eb10-579e-8560-4a9242c79595"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[compat]
Aqua = "0.6"
```

Note that Aqua 0.5 and 0.4 are still maintained.  Aqua 0.4, 0.5, and 0.6 are
different only by the default enabled flags as of writing.

## Badge

You can add the following line in README.md to include Aqua.jl badge:

```markdown
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
```

which is rendered as

> [![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
