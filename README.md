# Aqua.jl: *A*uto *QU*ality *A*ssurance for Julia packages

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Aqua.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Aqua.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Aqua.jl.svg?branch=master)](https://travis-ci.com/tkf/Aqua.jl)
[![Codecov](https://codecov.io/gh/tkf/Aqua.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Aqua.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Aqua.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Aqua.jl?branch=master)

## Usage

Call `Aqua.test_all(YourPackage)` from `test/runtests.jl`, e.g.,

```julia
using YourPackage
using Aqua
Aqua.test_all(YourPackage)
```
