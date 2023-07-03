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

## Setup

Please consult the [documentation](https://juliatesting.github.io/Aqua.jl/dev) for the latest instructions.

## Badge

You can add the following line in README.md to include Aqua.jl badge:

```markdown
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
```

which is rendered as

> [![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
