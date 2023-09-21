"""
    Aqua.test_persistent_tasks(package; tmax=5)

Test whether loading `package` creates persistent `Task`s
which may block precompilation of dependent packages.

# Motivation

Julia 1.10 and higher wait for all running `Task`s to finish
before writing out the precompiled (cached) version of the package.
One consequence is that a package that launches
`Task`s in its `__init__` function may precompile successfully,
but block precompilation of any packages that depend on it.

# Example

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

# How the test works

This test works by launching a Julia process that tries to precompile a
dummy package similar to `PkgB` above, modified to signal back to Aqua when
`PkgA` has finished loading. The test fails if the gap between loading `PkgA`
and finishing precompilation exceeds time `tmax`.

# How to fix failing packages

Often, the easiest fix is to modify the `__init__` function to check whether the
Julia process is precompiling some other package; if so, don't launch the
persistent `Task`s.

```
function __init__()
    # Other setup code here
    if ccall(:jl_generating_output, Cint, ()) == 0   # if we're not precompiling...
        # launch persistent tasks here
    end
end
```

In more complex cases, you may need to set up independently-callable functions
to launch the tasks and set conditions that allow them to cleanly exit.

# Arguments
- `package`: a top-level `Module` or `Base.PkgId`.

# Keyword Arguments
- `tmax::Real`: the maximum time (in seconds) to wait after loading the
  package before forcibly shutting down the precompilation process (triggering
  a test failure).
"""
function test_persistent_tasks(package::PkgId; tmax = 10, broken::Bool = false)
    @testset "$package persistent_tasks" begin
        result = root_project_or_failed_lazytest(package)
        result isa LazyTestResult && return result
        @test broken ⊻ precompile_wrapper(result, tmax)
    end
end

function test_persistent_tasks(package::Module; kwargs...)
    test_persistent_tasks(PkgId(package); kwargs...)
end

"""
    Aqua.test_persistent_tasks_deps(package; broken = Dict{String,Bool}(), kwargs...)

Test all the dependencies of `package` with [`Aqua.test_persistent_tasks`](@ref).
On Julia 1.10 and higher, you may see a summary of the test results similar to this:

```
Test Summary:                                                             | Pass  Fail  Total   Time
/path/to/Project.toml                                                     |    1     1      2  10.2s
  TransientTask [94ae9332-58b0-4342-989c-0a7e44abcca9] persistent_tasks   |    1            1   2.5s
  PersistentTask [e5c298b6-d81d-47aa-a9ed-5ea983e22986] persistent_tasks  |          1      1   7.7s
ERROR: Some tests did not pass: 1 passed, 1 failed, 0 errored, 0 broken.
```

The dependencies that fail are likely the ones blocking precompilation of your package.

`get(broken, dep, false)` encodes whether dependency `dep` is expected to fail the test
(this is primarily intended for use in Aqua's own internal test suite).
Any additional kwargs (e.g., `tmax`) are passed to [`Aqua.test_persistent_tasks`](@ref).
"""
function test_persistent_tasks_deps(package::PkgId; broken = Dict{String,Bool}(), kwargs...)
    result = root_project_or_failed_lazytest(package)
    result isa LazyTestResult && return result
    prj = TOML.parsefile(result)
    deps = get(prj, "deps", nothing)
    @testset "$result" begin
        if deps === nothing
            return LazyTestResult("$package", "`$result` does not have `deps`", true)
        else
            for (name, uuid) in deps
                id = PkgId(UUID(uuid), name)
                test_persistent_tasks(id; broken = get(broken, name, false), kwargs...)
            end
        end
    end
end

function test_persistent_tasks_deps(package::Module; kwargs...)
    test_persistent_tasks_deps(PkgId(package); kwargs...)
end

function precompile_wrapper(project, tmax)
    pkgdir = dirname(project)
    pkgname = basename(pkgdir)
    wrapperdir = tempname()
    wrappername, _ = only(Pkg.generate(wrapperdir))
    Pkg.activate(wrapperdir)
    Pkg.develop(PackageSpec(path = pkgdir))
    statusfile = joinpath(wrapperdir, "done.log")
    open(joinpath(wrapperdir, "src", wrappername * ".jl"), "w") do io
        println(
            io,
            """
module $wrappername
using $pkgname
# Signal Aqua from the precompilation process that we've finished loading the package
open("$(escape_string(statusfile))", "w") do io
    println(io, "done")
    flush(io)
end
end
""",
        )
    end
    # Precompile the wrapper package
    cmd = `$(Base.julia_cmd()) --project=$wrapperdir -e 'using Pkg; Pkg.precompile()'`
    proc = run(cmd; wait = false)
    while !isfile(statusfile) && process_running(proc)
        sleep(0.5)
    end
    if !isfile(statusfile)
        @error "Unexpected error: $statusfile was not created, but precompilation exited"
        return false
    end
    # Check whether precompilation finishes in the required time
    t = time()
    while process_running(proc) && time() - t < tmax
        sleep(0.1)
    end
    success = !process_running(proc)
    if !success
        kill(proc)
    end
    return success
end