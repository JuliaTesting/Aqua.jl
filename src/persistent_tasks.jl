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
to launch the tasks and cleanly shut them down.

# Arguments
- `package`: a top-level `Module` or `Base.PkgId`.

# Keyword Arguments
- `tmax::Real`: the maximum time (in seconds) to wait between loading the
  package and forced shutdown of the precompilation process.
"""
function test_persistent_tasks(package::PkgId; tmax=5, fails::Bool=false)
    @testset "$package persistent_tasks" begin
        result = root_project_or_failed_lazytest(package)
        result isa LazyTestResult && return result
        @test fails ⊻ precompile_wrapper(result, tmax)
    end
end

function test_persistent_tasks(package::Module; kwargs...)
    test_persistent_tasks(PkgId(package); kwargs...)
end

"""
    Aqua.test_persistent_tasks_deps(package; kwargs...)

Test all the dependencies of `package` with [`Aqua.test_persistent_tasks`](@ref).
"""
function test_persistent_tasks_deps(package::PkgId; fails=Dict{String,Bool}(), kwargs...)
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
                test_persistent_tasks(id; fails=get(fails, name, false), kwargs...)
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
    wrappername, wrapperuuid = only(Pkg.generate(wrapperdir))
    Pkg.activate(wrapperdir)
    Pkg.develop(PackageSpec(path=pkgdir))
    open(joinpath(wrapperdir, "src", wrappername * ".jl"), "w") do io
        println(io, """
        module $wrappername
        using $pkgname
        # Signal Aqua from the precompilation process that we've finished loading the package
        open(joinpath("$wrapperdir", "done.log"), "w") do io
            println(io, "done")
        end
        end
        """)
    end
    # Precompile the wrapper package
    cmd = `$(Base.julia_cmd()) --project=$wrapperdir -e 'using Pkg; Pkg.precompile()'`
    proc = run(cmd; wait=false)
    while !isfile(joinpath(wrapperdir, "done.log"))
        sleep(0.1)
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
