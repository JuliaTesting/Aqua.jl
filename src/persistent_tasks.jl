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
  precompilation process to exit *after* `package` has finished loading. Only
  this shutdown counts against `tmax`, not the time spent loading the
  dependencies. A persistent `Task` blocks the exit indefinitely, so if a
  package free of persistent tasks is misreported, increase `tmax`.
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
    launched = launch_persistent_tasks_check(package; expr)
    return await_persistent_tasks_check(launched, tmax)
end

function launch_persistent_tasks_check(package::PkgId; expr::Expr = quote end)
    @static VERSION >= v"1.10.0-" || return false
    root_project_path, found = root_project_toml(package)
    found || error("Unable to locate Project.toml")
    handle = launch_precompile_wrapper(root_project_path, expr)
    handle === nothing && return true
    return handle
end

await_persistent_tasks_check(verdict::Bool, tmax) = verdict
await_persistent_tasks_check(handle, tmax) = !await_precompile_wrapper(handle, tmax)

function _launch_persistent_tasks(
    package::PkgId;
    broken::Bool = false,
    expr::Expr = quote end,
    tmax = 30,
)
    launched = launch_persistent_tasks_check(package; expr)
    return (; launched, broken, tmax)
end

function _await_persistent_tasks(launch_task)
    pending = fetch(launch_task)
    has = await_persistent_tasks_check(pending.launched, pending.tmax)
    return (; has, broken = pending.broken)
end

function _report_persistent_tasks(result)
    if result.broken
        @test_broken !result.has
    else
        @test !result.has
    end
end

function _stop_persistent_tasks(launch_task)
    pending = try
        fetch(launch_task)
    catch
        return
    end
    stop_precompile_wrapper(pending.launched)
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
    deps = collect(get(prj, "deps", Dict{String,Any}()))
    # Julia 1.12 and earlier cannot instantiate environments concurrently.
    ntasks = if VERSION >= v"1.13-"
        max(1, min(length(deps), Sys.CPU_THREADS))
    else
        1
    end
    results = asyncmap(deps; ntasks = ntasks) do (name, uuid)
        id = PkgId(UUID(uuid), name)
        return name => has_persistent_tasks(id; kwargs...)
    end
    return String[name for (name, hastasks) in results if hastasks]
end

function find_persistent_tasks_deps(package::Module; kwargs...)
    find_persistent_tasks_deps(PkgId(package); kwargs...)
end

function precompile_wrapper(project, tmax, expr)
    @static if VERSION < v"1.10.0-"
        return true
    end
    handle = launch_precompile_wrapper(project, expr)
    handle === nothing && return false
    return await_precompile_wrapper(handle, tmax)
end

# Pkg activation and sysimage-version handling are process-global.
const PRECOMPILE_SETUP_LOCK = ReentrantLock()

function launch_precompile_wrapper(project, expr)
    pkgdir = dirname(project)
    pkgname = get(TOML.parsefile(project), "name", "")::String
    if isempty(pkgname)
        @error "Unable to locate package name in $project"
        return nothing
    end
    wrapperdir = tempname()
    statusfile = joinpath(wrapperdir, "done.log")
    errlog = joinpath(wrapperdir, "precompile-stderr.log")
    currently_precompiling = @ccall(jl_generating_output()::Cint) == 1
    lock(PRECOMPILE_SETUP_LOCK) do
        prev_project = Base.active_project()::String
        respect_sysimage_versions =
            isdefined(Pkg, :respect_sysimage_versions) ?
            Pkg.RESPECT_SYSIMAGE_VERSIONS[] : nothing
        respect_sysimage_versions === nothing || Pkg.respect_sysimage_versions(false)
        try
            wrappername, _ = only(Pkg.generate(wrapperdir; io = devnull))
            Pkg.activate(wrapperdir; io = devnull)
            Pkg.develop(PackageSpec(path = pkgdir); io = devnull)
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
        finally
            respect_sysimage_versions === nothing ||
                Pkg.respect_sysimage_versions(respect_sysimage_versions)
            Pkg.activate(prev_project; io = devnull)
        end
    end
    # Precompile the wrapper package
    cmd = if currently_precompiling
        # During precompilation we run a dummy command that just touches the
        # status file to keep things simple.
        code = """touch("$(escape_string(statusfile))")"""
        `$(Base.julia_cmd()) -e $code`
    else
        `$(Base.julia_cmd()) --project=$wrapperdir -e 'push!(LOAD_PATH, "@stdlib"); using Pkg; Pkg.precompile()'`
    end

    # Capture the subprocess's stderr so a genuine precompilation error can be
    # reported on its own terms instead of masquerading as a persistent task.
    cmd = pipeline(cmd; stdout = devnull, stderr = errlog)
    proc = run(cmd; wait = false)::Base.Process
    return (; proc, statusfile, errlog, pkgname)
end

function await_precompile_wrapper(handle, tmax)
    proc = handle.proc
    statusfile = handle.statusfile
    pkgname = handle.pkgname

    # Loading time does not count against the persistent-task timeout.
    timedwait(() -> isfile(statusfile) || !process_running(proc), Inf; pollint = 0.5)
    if !isfile(statusfile)
        precompile_error(handle)
    end

    # Once loaded, a process that does not exit within `tmax` has a persistent task.
    timedwait(() -> !process_running(proc), tmax; pollint = 0.1)
    if process_running(proc)
        @warn(
            "Loading `$pkgname` prevented the precompilation process from " *
            "exiting within $tmax seconds, which usually means a persistent " *
            "task is still running. If `$pkgname` is free of persistent tasks, " *
            "re-run with a larger `tmax` to give its shutdown more time."
        )
        # SIGKILL to prevent julia from printing the SIG 15 handler, which can
        # misleadingly look like it's caused by an issue in the user's program.
        kill(proc, Base.SIGKILL)
        wait(proc)
        return false
    end
    wait(proc)
    iszero(proc.exitcode) || precompile_error(handle)
    return true
end

function precompile_error(handle)
    proc = handle.proc
    wait(proc)
    error(
        "Loading `$(handle.pkgname)` for the persistent-task check failed " *
        "during precompilation (process exited with code $(proc.exitcode), " *
        "signal $(proc.termsignal)). This indicates a precompilation error, " *
        "not a persistent task." *
        (
            isfile(handle.errlog) ?
            "\nCaptured output:\n\n" * read(handle.errlog, String) : ""
        ),
    )
end

stop_precompile_wrapper(::Bool) = nothing
function stop_precompile_wrapper(handle)
    process_running(handle.proc) && kill(handle.proc, Base.SIGKILL)
    wait(handle.proc)
end
