"""
    Aqua.test_persistent_tasks(package)

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

On julia version 1.9 and before, this test always succeeds.

# Arguments
- `package`: a top-level `Module` or `Base.PkgId`.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test`.
- `tmax::Real = 5`: the maximum time (in seconds) to wait after loading the
  package before forcibly shutting down the precompilation process (triggering
  a test failure).
"""
function test_persistent_tasks(package::PkgId; broken::Bool = false, kwargs...)
    if broken
        @test_broken !has_persistent_tasks(package; kwargs...)
    else
        @test !has_persistent_tasks(package; kwargs...)
    end
end

function test_persistent_tasks(package::Module; kwargs...)
    test_persistent_tasks(PkgId(package); kwargs...)
end

function has_persistent_tasks(package::PkgId; tmax = 10)
    result = root_project_or_failed_lazytest(package)
    result isa LazyTestResult && error("Unable to locate Project.toml")
    return !precompile_wrapper(result, tmax)
end

"""
    Aqua.find_persistent_tasks_deps(package; broken = Dict{String,Bool}(), kwargs...)

Test all the dependencies of `package` with [`Aqua.test_persistent_tasks`](@ref).
On Julia 1.10 and higher, it returns a list of all dependencies failing the test.
These are likely the ones blocking precompilation of your package.

Any additional kwargs (e.g., `tmax`) are passed to [`Aqua.test_persistent_tasks`](@ref).
"""
function find_persistent_tasks_deps(package::PkgId; kwargs...)
    result = root_project_or_failed_lazytest(package)
    result isa LazyTestResult && error("Unable to locate Project.toml")
    prj = TOML.parsefile(result)
    deps = get(prj, "deps", Dict{String,Any}())
    filter!(deps) do (name, uuid)
        id = PkgId(UUID(uuid), name)
        return has_persistent_tasks(id; kwargs...)
    end
    return [name for (name, _) in deps]
end

function find_persistent_tasks_deps(package::Module; kwargs...)
    find_persistent_tasks_deps(PkgId(package); kwargs...)
end

function precompile_wrapper(project, tmax)
    if VERSION < v"1.10.0-"
        return true
    end
    prev_project = Base.active_project()
    isdefined(Pkg, :respect_sysimage_versions) && Pkg.respect_sysimage_versions(false)
    try
        pkgdir = dirname(project)
        pkgname = get(TOML.parsefile(project), "name", nothing)
        if isnothing(pkgname)
            @error "Unable to locate package name in $project"
            return false
        end
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
    finally
        isdefined(Pkg, :respect_sysimage_versions) && Pkg.respect_sysimage_versions(true)
        Pkg.activate(prev_project)
    end
end
