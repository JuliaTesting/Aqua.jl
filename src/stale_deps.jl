"""
    Aqua.test_stale_deps(package; ignore::AbstractVector{Symbol} = Symbol[])

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
    dependencies when they are in the sysimage. This is considered a
    bug and may be fixed in the future. Such a release is considered
    non-breaking.

# Arguments
- `packages`: a top-level `Module`, a `Base.PkgId`, or a collection of
  them.

# Keyword Arguments
- `ignore`: names of dependent packages to be ignored.
"""
function test_stale_deps(pkg::PkgId; kwargs...)
    stale_deps = find_stale_deps(pkg; kwargs...)
    @test isempty(stale_deps)
end

function test_stale_deps(mod::Module; kwargs...)
    test_stale_deps(aspkgid(mod); kwargs...)
end

# Remove in next breaking release
function test_stale_deps(packages::Vector{<:Union{Module,PkgId}}; kwargs...)
    @testset "$pkg" for pkg in packages
        test_stale_deps(pkg; kwargs...)
    end
end

function find_stale_deps(pkg::PkgId; ignore::AbstractVector{Symbol} = Symbol[])
    root_project_path, found = root_project_toml(pkg)
    found || error("Unable to locate Project.toml")

    prj = TOML.parsefile(root_project_path)
    deps::Vector{PkgId} =
        PkgId[PkgId(UUID(v), k) for (k::String, v::String) in get(prj, "deps", Dict())]
    weakdeps::Vector{PkgId} =
        PkgId[PkgId(UUID(v), k) for (k::String, v::String) in get(prj, "weakdeps", Dict())]

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
    pos = findfirst(marker, output)
    @assert !isnothing(pos)
    output = output[pos.stop+1:end]
    loaded_uuids = map(UUID, eachline(IOBuffer(output)))

    return find_stale_deps_2(;
        deps = deps,
        weakdeps = weakdeps,
        loaded_uuids = loaded_uuids,
        ignore = ignore,
    )
end

# Side-effect -free part of stale dependency analysis.
function find_stale_deps_2(;
    deps::AbstractVector{PkgId},
    weakdeps::AbstractVector{PkgId},
    loaded_uuids::AbstractVector{UUID},
    ignore::AbstractVector{Symbol},
)
    deps_uuids = [p.uuid for p in deps]
    pkgid_from_uuid = Dict(p.uuid => p for p in deps)

    stale_uuids = setdiff(deps_uuids, loaded_uuids)
    stale_pkgs = PkgId[pkgid_from_uuid[uuid] for uuid in stale_uuids]
    stale_pkgs = setdiff(stale_pkgs, weakdeps)
    stale_pkgs = PkgId[p for p in stale_pkgs if !(Symbol(p.name) in ignore)]

    return stale_pkgs
end
