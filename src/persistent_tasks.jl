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
    `package` and its dependencies are taken from where the current process
    loads them, so `dev`ed dependencies and dependencies tracked by a local path
    or a git repository in the `Manifest.toml` are supported.
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

# Manifest entries for the package at `pkgdir` and its dependencies, each taken
# from where the current process loads it, so `dev`ed and path-tracked packages
# are found without resolving anything.
function manifest_entries(pkgdir::String)
    entries = Dict{String,Vector{Dict{String,Any}}}()
    seen = Set{String}()
    function visit(pkgdir)
        project_file, found = project_toml_path(pkgdir)
        found || error("Unable to locate Project.toml in $pkgdir")
        prj = TOML.parsefile(project_file)
        uuid = prj["uuid"]::String
        uuid in seen && return
        push!(seen, uuid)
        entry = Dict{String,Any}("uuid" => uuid)
        for key in ("version", "deps", "weakdeps", "extensions")
            haskey(prj, key) && (entry[key] = prj[key])
        end
        # Without `path`, Julia looks the package up in `Sys.STDLIB`.
        startswith(pkgdir, Sys.STDLIB) || (entry["path"] = pkgdir)
        push!(get!(Vector{Dict{String,Any}}, entries, prj["name"]::String), entry)
        for (name, dep_uuid) in get(prj, "deps", Dict{String,Any}())
            srcpath = Base.locate_package(PkgId(UUID(dep_uuid), name))
            srcpath === nothing &&
                error("Unable to locate `$name`, a dependency of `$(prj["name"])`")
            visit(dirname(dirname(srcpath)))
        end
    end
    visit(pkgdir)
    return entries
end

function precompile_wrapper(project, tmax, expr)
    @static if VERSION < v"1.10.0-"
        return true
    end
    pkgdir = dirname(project)
    prj = TOML.parsefile(project)
    pkgname = get(prj, "name", "")::String
    if isempty(pkgname)
        @error "Unable to locate package name in $project"
        return false
    end
    wrapperdir = tempname()
    wrappername, _ = only(Pkg.generate(wrapperdir; io = devnull))
    # Add the package as a dependency and write a manifest mirroring the current
    # environment instead of resolving one with `Pkg.develop`.
    wrapper_project_file = joinpath(wrapperdir, "Project.toml")
    wrapper_project = TOML.parsefile(wrapper_project_file)
    wrapper_project["deps"] = Dict{String,Any}(pkgname => prj["uuid"])
    open(io -> TOML.print(io, wrapper_project), wrapper_project_file, "w")
    manifest = Dict{String,Any}(
        "julia_version" => string(VERSION),
        "manifest_format" => "2.0",
        "deps" => manifest_entries(pkgdir),
    )
    open(io -> TOML.print(io, manifest), joinpath(wrapperdir, "Manifest.toml"), "w")
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

    # Capture the subprocess's stderr so a genuine precompilation error can be
    # reported on its own terms instead of masquerading as a persistent task.
    errlog = joinpath(wrapperdir, "precompile-stderr.log")
    cmd = pipeline(cmd; stdout = devnull, stderr = errlog)
    proc = run(cmd; wait = false)::Base.Process

    # Phase 1 (unbounded): wait for the package to finish loading. The wrapper
    # writes `statusfile` once `using $pkgname` (and any `expr`) has run. Slow
    # precompilation of the dependencies only prolongs this phase.
    timedwait(() -> isfile(statusfile) || !process_running(proc), Inf; pollint = 0.5)
    if !isfile(statusfile)
        # The process exited before the package finished loading: a
        # precompilation failure, not a persistent task.
        wait(proc)
        error(
            "Loading `$pkgname` for the persistent-task check failed before " *
            "precompilation completed (process exited with code " *
            "$(proc.exitcode), signal $(proc.termsignal)). This indicates a " *
            "precompilation error, not a persistent task." *
            (isfile(errlog) ? "\nCaptured output:\n\n" * read(errlog, String) : ""),
        )
    end

    # Phase 2 (bounded by `tmax`): the package loaded cleanly. A persistent task
    # keeps the process from exiting, so it hangs indefinitely. A healthy package
    # exits once its shutdown finishes, so allow up to `tmax` seconds for it.
    timedwait(() -> !process_running(proc), tmax; pollint = 0.1)
    success = !process_running(proc)
    if !success
        @warn(
            "Loading `$pkgname` prevented the precompilation process from " *
            "exiting within $tmax seconds, which usually means a persistent " *
            "task is still running. If `$pkgname` is free of persistent tasks, " *
            "re-run with a larger `tmax` to give its shutdown more time."
        )
        # SIGKILL to prevent julia from printing the SIG 15 handler, which can
        # misleadingly look like it's caused by an issue in the user's program.
        kill(proc, Base.SIGKILL)
    end
    return success
end
