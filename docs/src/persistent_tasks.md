# Persistent Tasks

## Motivation

Julia 1.10 and higher wait for all running `Task`s to finish
before writing out the precompiled (cached) version of the package.
One consequence is that a package that launches
`Task`s in its `__init__` function may precompile successfully,
but block precompilation of any packages that depend on it.

The symptom of this problem is a message
```
◐ MyPackage: Waiting for background task / IO / timer. Interrupt to inspect...
```
that may appear during precompilation, with that precompilation process
"hanging" until you press Ctrl-C.

Aqua has checks to determine whether your package *causes* this problem.
Conversely, if you're a *victim* of this problem, it also has tools to help you
determine which of your dependencies is causing the problem.

## Example

Let's create a dummy package, `PkgA`, that launches a persistent `Task`:

```julia
module PkgA
const t = Ref{Timer}()   # used to prevent the Timer from being garbage-collected
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

Without Aqua's tests, the developers of `PkgA` might not realize that their
package is essentially unusable with any other package.

## Checking for persistent tasks

Running all of Aqua's tests will automatically check whether your package falls
into this trap. In addition, there are ways to manually run (or tweak) this
specific test.

### Manually running the persistent-tasks check

[`Aqua.test_persistent_tasks(MyPackage)`](@ref) will check whether `MyPackage` blocks
precompilation for any packages that depend on it.

### Using an `expr` to check more than just `__init__`

By default, `Aqua.test_persistent_tasks` only checks whether a package's
`__init__` function leaves persistent tasks running. To check whether other
package functions leave persistent tasks running, pass a quoted expression:

```julia
Aqua.test_persistent_tasks(MyPackage, quote
    # Code to run after loading MyPackage
    server = MyPackage.start_server()
    MyPackage.stop_server!(server)  # ideally, this this should cleanly shut everything down. Does it?
end)
```

Here is an example test with a dummy `expr` which will obviously fail, because it's explicitly
spawning a Task that never dies.
```@repl
using Aqua
Aqua.test_persistent_tasks(Aqua, expr = quote
    Threads.@spawn while true sleep(0.5) end
end)
```

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

In more complex cases, you may need to modify the task to support a clean
shutdown. For example, if you have a `Task` that runs a never-terminating
`while` loop, you could change

```
    while true
        ⋮
    end
```

to

```
    while task_should_run[]
        ⋮
    end
```

where

```
const task_should_run = Ref(true)
```

is a global constant in your module. Setting `task_should_run[] = false` from
outside that `while` loop will cause it to terminate on its next iteration,
allowing the `Task` to finish.

## Additional information

[Julia's devdocs](https://docs.julialang.org/en/v1/devdocs/precompile_hang/)
also discuss this issue.

## [Test functions](@id test_persistent_tasks)

```@docs
Aqua.test_persistent_tasks
Aqua.find_persistent_tasks_deps
```
