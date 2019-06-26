# Aqua.jl: *A*uto *QU*ality *A*ssurance for Julia packages

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Aqua.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Aqua.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Aqua.jl.svg?branch=master)](https://travis-ci.com/tkf/Aqua.jl)
[![Codecov](https://codecov.io/gh/tkf/Aqua.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Aqua.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Aqua.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Aqua.jl?branch=master)
[![GitHub commits since tagged version](https://img.shields.io/github/commits-since/tkf/Aqua.jl/v0.4.0.svg)](https://github.com/tkf/Aqua.jl)
[![Aqua QA](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/tkf/Aqua.jl)

Aqua.jl provides functions to run a few automatable checks for Julia packages:

* There are no method ambiguities.
* There are no undefined `export`s.
* There are no unbound type parameters.

## Quick usage

Call `Aqua.test_all(YourPackage)` from `test/runtests.jl`, e.g.,

```julia
using YourPackage
using Aqua
Aqua.test_all(YourPackage)
```

See more in the [documentation](https://tkf.github.io/Aqua.jl/dev).
