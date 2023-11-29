# Persistent Tasks

## Motivation

Julia 1.10 and higher wait for all running `Task`s to finish
before writing out the precompiled (cached) version of the package.
One consequence is that a package that launches
`Task`s in its `__init__` function may precompile successfully,
but block precompilation of any packages that depend on it.

## Example

Let's create a dummy package, `PkgA`, that launches a persistent `Task`:

```julia
module PkgA
const t = Ref{Any}()   # to prevent the Timer from being garbage-collected
__init__() = t[] = Timer(0.1; interval=1)   # create a persistent `Timer` `Task`
end
```

`PkgA` will precompile successfully, because `PkgA.__init__()` does not
run when `PkgA` is precompiled. However,

```julia
module PkgB
using PkgA
end
```

fails to precompile: `using PkgA` runs `PkgA.__init__()`, which
leaves the `Timer` `Task` running, and that causes precompilation
of `PkgB` to hang.

## How the test works

This test works by launching a Julia process that tries to precompile a
dummy package similar to `PkgB` above, modified to signal back to Aqua when
`PkgA` has finished loading. The test fails if the gap between loading `PkgA`
and finishing precompilation exceeds time `tmax`.

## How to fix failing packages

Often, the easiest fix is to modify the `__init__` function to check whether the
Julia process is precompiling some other package; if so, don't launch the
persistent `Task`s.

```julia
function __init__()
    # Other setup code here
    if ccall(:jl_generating_output, Cint, ()) == 0   # if we're not precompiling...
        # launch persistent tasks here
    end
end
```

In more complex cases, you may need to set up independently-callable functions
to launch the tasks and set conditions that allow them to cleanly exit.

## [Test functions](@id test_persistent_tasks)

```@docs
Aqua.test_persistent_tasks
Aqua.find_persistent_tasks_deps
```
