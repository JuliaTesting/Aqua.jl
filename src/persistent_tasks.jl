"""
    Aqua.test_persistent_tasks(package)

Test whether loading `package` creates persistent `Task`s
which may block precompilation of dependent packages.

See also [`Aqua.find_persistent_tasks_deps`](@ref).

If you provide an optional `expr`, this tests whether loading `package` and running `expr`
creates persistent `Task`s. For example, you might start and shutdown a web server, and
this will test that there aren't any persistent `Task`s.

On Julia version 1.9 and before, this test always succeeds.

# Arguments
- `package`: a top-level `Module` or `Base.PkgId`.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test`.
- `tmax::Real = 30`: the maximum time (in seconds) to wait for the
  precompilation process to exit *after* `package` has finished loading, before
  concluding that a persistent `Task` is holding the process open (triggering a
  test failure). Only the shutdown of an already-loaded package counts against
  this budget; the time spent precompiling and loading the dependencies
  does not. A persistent `Task` blocks precompilation indefinitely, whereas a
  healthy package always exits eventually, so a slow-but-clean shutdown with
  many or cold-cached dependencies (for example under `Pkg.test`'s
  `--check-bounds=yes`) is *not* a persistent task. If such a package is
  misreported, increase `tmax`.
- `expr::Expr = quote end`: An expression to run in the precompile package.

!!! note

    `Aqua.test_persistent_tasks(package)` creates a package with `package`
    as a dependency and runs the precompilation process.
    This requires that `package` is instantiable with the information in the
    `Project.toml` file alone.
    In particular, this will not work if some of `package`'s dependencies are `dev`ed
    packages or are given as a local path or a git repository in the `Manifest.toml`.
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

function has_persistent_tasks(package::PkgId; expr::Expr = quote end, tmax = 30)
    root_project_path, found = root_project_toml(package)
    found || error("Unable to locate Project.toml")
    return !precompile_wrapper(root_project_path, tmax, expr)
end

"""
    Aqua.find_persistent_tasks_deps(package; kwargs...)

Test all the dependencies of `package` with [`Aqua.test_persistent_tasks`](@ref).

On Julia 1.10 and higher, it returns a list of all dependencies failing the test.
These are likely the ones blocking precompilation of your package.

Any `kwargs` are passed to [`Aqua.test_persistent_tasks`](@ref).
"""
function find_persistent_tasks_deps(package::PkgId; kwargs...)
    root_project_path, found = root_project_toml(package)
    found || error("Unable to locate Project.toml")
    prj = TOML.parsefile(root_project_path)
    deps = get(prj, "deps", Dict{String,Any}())
    filter!(deps) do (name, uuid)
        id = PkgId(UUID(uuid), name)
        return has_persistent_tasks(id; kwargs...)
    end
    return String[name for (name, _) in deps]
end

function find_persistent_tasks_deps(package::Module; kwargs...)
    find_persistent_tasks_deps(PkgId(package); kwargs...)
end

function precompile_wrapper(project, tmax, expr)
    @static if VERSION < v"1.10.0-"
        return true
    end
    prev_project = Base.active_project()::String
    isdefined(Pkg, :respect_sysimage_versions) && Pkg.respect_sysimage_versions(false)
    try
        pkgdir = dirname(project)
        pkgname = get(TOML.parsefile(project), "name", "")::String
        if isempty(pkgname)
            @error "Unable to locate package name in $project"
            return false
        end
        wrapperdir = tempname()
        wrappername, _ = only(Pkg.generate(wrapperdir; io = devnull))
        Pkg.activate(wrapperdir; io = devnull)
        Pkg.develop(PackageSpec(path = pkgdir); io = devnull)
        statusfile = joinpath(wrapperdir, "done.log")
        open(joinpath(wrapperdir, "src", wrappername * ".jl"), "w") do io
            println(
                io,
                """
module $wrappername
using $pkgname
$expr
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
        currently_precompiling = @ccall(jl_generating_output()::Cint) == 1
        cmd = if currently_precompiling
            # During precompilation we run a dummy command that just touches the
            # status file to keep things simple.
            code = """touch("$(escape_string(statusfile))")"""
            `$(Base.julia_cmd()) -e $code`
        else
            `$(Base.julia_cmd()) --project=$wrapperdir -e 'push!(LOAD_PATH, "@stdlib"); using Pkg; Pkg.precompile()'`
        end

        # Capture the subprocess's stderr so that a genuine precompilation error
        # can be distinguished from a persistent task and reported on its own terms
        # instead of masquerading as a persistent-task failure. `Pkg.precompile`
        # writes its error report to stderr; the capture is reported only when
        # precompilation fails. stdout is discarded to keep a passing run quiet.
        errlog = joinpath(wrapperdir, "precompile-stderr.log")
        cmd = pipeline(cmd; stdout = devnull, stderr = errlog)
        proc = run(cmd; wait = false)::Base.Process

        # Phase 1 (unbounded): wait for the package to finish loading. The wrapper
        # writes `statusfile` from inside precompilation once `using $pkgname` (and
        # any `expr`) has run. Slow, cold, or `--check-bounds=yes` precompilation of
        # the dependencies only prolongs this phase; it never counts against
        # the persistent-task verdict.
        timedwait(() -> isfile(statusfile) || !process_running(proc), Inf; pollint = 0.5)
        if !isfile(statusfile)
            # The process exited before the package finished loading. This is a
            # precompilation failure in `$pkgname` or one of its dependencies, not
            # a persistent task, so report it as its own error rather than a
            # misleading persistent-task result.
            wait(proc)
            error(
                "Loading `$pkgname` for the persistent-task check failed before " *
                "precompilation completed (process exited with code " *
                "$(proc.exitcode)). This indicates a precompilation error, not a " *
                "persistent task. Captured output:\n\n" *
                (isfile(errlog) ? read(errlog, String) : ""),
            )
        end

        # Phase 2 (bounded by `tmax`): the package loaded cleanly. A persistent task
        # keeps the precompilation process from ever writing its cache and exiting,
        # so it hangs indefinitely. A healthy package exits once cache serialization
        # and runtime teardown finish; with many or cold-cached dependencies this
        # can still take a while, so allow up to `tmax` seconds before concluding
        # that a task is holding the process open.
        timedwait(() -> !process_running(proc), tmax; pollint = 0.1)
        success = !process_running(proc)
        if !success
            @warn(
                "Loading `$pkgname` prevented the precompilation process from " *
                "exiting within $tmax seconds, which usually means a persistent " *
                "task is still running. If `$pkgname` merely has many or " *
                "slow-to-precompile dependencies, a clean shutdown may need " *
                "more time; re-run with a larger `tmax` to rule that out."
            )
            # SIGKILL to prevent julia from printing the SIG 15 handler, which can
            # misleadingly look like it's caused by an issue in the user's program.
            kill(proc, Base.SIGKILL)
        end
        return success
    finally
        isdefined(Pkg, :respect_sysimage_versions) && Pkg.respect_sysimage_versions(true)
        Pkg.activate(prev_project; io = devnull)
    end
end
