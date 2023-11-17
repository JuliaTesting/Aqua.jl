"""
    Aqua.test_stale_deps(package; [ignore])

Test that `package` loads all dependencies listed in `Project.toml`.
Note that this does not imply that `package` loads the dependencies
directly, this can be achieved via transitivity as well.

!!! note "Weak dependencies and extensions"

    Due to the automatic loading of package extensions once all of
    their trigger dependencies are loaded, Aqua.jl can, by design of julia,
    not check if a package extension indeed loads all of its trigger
    dependencies using `import` or `using`. 

!!! warning "Known bug"

    Currently, `Aqua.test_stale_deps` does not detect stale
    dependencies when they are stdlib.  This is considered a bug and
    may be fixed in the future.  Such a release is considered
    non-breaking.

# Arguments
- `packages`: a top-level `Module`, a `Base.PkgId`, or a collection of
  them.

# Keyword Arguments
- `ignore::Vector{Symbol}`: names of dependent packages to be ignored.
"""
function test_stale_deps(packages; kwargs...)
    @testset "$(result.label)" for result in analyze_stale_deps(packages, kwargs...)
        @debug result.label result
        @test result ⊜ true
    end
end

analyze_stale_deps(packages, kwargs...) =
    [_analyze_stale_deps_1(pkg; kwargs...) for pkg in aspkgids(packages)]

function _analyze_stale_deps_1(pkg::PkgId; ignore::AbstractVector{Symbol} = Symbol[])
    label = "$pkg"

    result = root_project_or_failed_lazytest(pkg)
    result isa LazyTestResult && return result
    root_project_path = result

    @debug "Parsing `$root_project_path`"
    prj = TOML.parsefile(root_project_path)
    raw_deps = get(prj, "deps", nothing)
    if raw_deps === nothing
        return LazyTestResult(label, "No `deps` table in `$root_project_path`", true)
    end
    deps = [PkgId(UUID(v), k) for (k, v) in raw_deps]

    raw_weakdeps = get(prj, "weakdeps", nothing)
    weakdeps =
        isnothing(raw_weakdeps) ? PkgId[] : [PkgId(UUID(v), k) for (k, v) in raw_weakdeps]

    marker = "_START_MARKER_"
    code = """
    $(Base.load_path_setup_code())
    Base.require($(reprpkgid(pkg)))
    print("$marker")
    for pkg in keys(Base.loaded_modules)
        pkg.uuid === nothing || println(pkg.uuid)
    end
    """
    cmd = Base.julia_cmd()
    output = read(`$cmd --startup-file=no --color=no -e $code`, String)
    @debug("Checked modules loaded in a separate process.", cmd, Text(code), Text(output))
    pos = findfirst(marker, output)
    @assert !isnothing(pos)
    output = output[pos.stop+1:end]
    loaded_uuids = map(UUID, eachline(IOBuffer(output)))

    return _analyze_stale_deps_2(;
        pkg = pkg,
        deps = deps,
        weakdeps = weakdeps,
        loaded_uuids = loaded_uuids,
        ignore = ignore,
    )
end

# Side-effect -free part of stale dependency analysis.
function _analyze_stale_deps_2(;
    pkg::PkgId,
    deps::AbstractVector{PkgId},
    weakdeps::AbstractVector{PkgId},
    loaded_uuids::AbstractVector{UUID},
    ignore::AbstractVector{Symbol},
)
    label = "$pkg"
    deps_uuids = [p.uuid for p in deps]
    pkgid_from_uuid = Dict(p.uuid => p for p in deps)

    stale_uuids = setdiff(deps_uuids, loaded_uuids)
    stale_pkgs = [pkgid_from_uuid[uuid] for uuid in stale_uuids]
    stale_pkgs = setdiff(stale_pkgs, weakdeps)
    stale_pkgs = [p for p in stale_pkgs if !(Symbol(p.name) in ignore)]

    if isempty(stale_pkgs)
        return LazyTestResult(
            label,
            """
            All packages in `deps` are loaded via `using $(pkg.name)`.
            """,
            true,
        )
    end

    stale_msg = join(("* $p" for p in stale_pkgs), "\n")
    msglines = [
        "Some package(s) in `deps` of $pkg are not loaded during via" *
        " `using $(pkg.name)`.",
        stale_msg,
        "",
        "To ignore from stale dependency detection, pass the package name to" *
        " `ignore` keyword argument of `Aqua.test_stale_deps`",
    ]
    return LazyTestResult(label, join(msglines, "\n"), false)
end
