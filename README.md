# Aqua.jl: *A*uto *QU*ality *A*ssurance for Julia packages

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliatesting.github.io/Aqua.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliatesting.github.io/Aqua.jl/dev)
[![Build Status](https://travis-ci.com/JuliaTesting/Aqua.jl.svg?branch=master)](https://travis-ci.com/JuliaTesting/Aqua.jl)
[![Codecov](https://codecov.io/gh/JuliaTesting/Aqua.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaTesting/Aqua.jl)
[![Coveralls](https://coveralls.io/repos/github/JuliaTesting/Aqua.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaTesting/Aqua.jl?branch=master)
[![GitHub commits since tagged version](https://img.shields.io/github/commits-since/JuliaTesting/Aqua.jl/v0.4.7.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Aqua QA](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/JuliaTesting/Aqua.jl)

Aqua.jl provides functions to run a few automatable checks for Julia packages:

* There are no method ambiguities.
* There are no undefined `export`s.
* There are no unbound type parameters.
* There are no stale dependencies listed in `Project.toml` (optional).
* Check that test target of the root project `Project.toml` and test project
  (`test/Project.toml`) are consistent (optional).
* Check that all external packages listed in `deps` have corresponding
  `compat` entry (optional).
* `Project.toml` formatting is compatible with Pkg.jl output (optional).

## Quick usage

Call `Aqua.test_all(YourPackage)` from `test/runtests.jl`, e.g.,

```julia
using YourPackage
using Aqua
Aqua.test_all(YourPackage)
```

See more in the [documentation](https://juliatesting.github.io/Aqua.jl/dev).
