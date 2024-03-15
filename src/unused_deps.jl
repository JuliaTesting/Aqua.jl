"""
    Aqua.test_unused_deps(package; [ignore])

Test that `package` loads all dependencies listed in `Project.toml`.
Note that this does not imply that `package` loads the dependencies
directly, this can be achieved via transitivity as well.

!!! note "Weak dependencies and extensions"

    Due to the automatic loading of package extensions once all of
    their trigger dependencies are loaded, Aqua.jl can, by design of julia,
    not check if a package extension indeed loads all of its trigger
    dependencies using `import` or `using`. 

!!! warning "Known bug"

    Currently, `Aqua.test_unused_deps` does not detect unused
    dependencies when they are in the sysimage. This is considered a 
    bug and may be fixed in the future. Such a release is considered
    non-breaking.

# Arguments
- `packages`: a top-level `Module`, a `Base.PkgId`, or a collection of
  them.

# Keyword Arguments
- `ignore::Vector{Symbol}`: names of dependent packages to be ignored.
"""
function test_unused_deps(pkg::PkgId; kwargs...)
    unused_deps = find_unused_deps(pkg; kwargs...)
    @test isempty(unused_deps)
end

function test_unused_deps(mod::Module; kwargs...)
    test_unused_deps(aspkgid(mod); kwargs...)
end

# Remove in next breaking release
function test_unused_deps(packages::Vector{<:Union{Module,PkgId}}; kwargs...)
    @testset "$pkg" for pkg in packages
        test_unused_deps(pkg; kwargs...)
    end
end

function find_unused_deps(pkg::PkgId; ignore::AbstractVector{Symbol} = Symbol[])
    root_project_path, found = root_project_toml(pkg)
    found || error("Unable to locate Project.toml")

    prj = TOML.parsefile(root_project_path)
    deps = [PkgId(UUID(v), k) for (k, v) in get(prj, "deps", Dict{String,Any}())]
    weakdeps = [PkgId(UUID(v), k) for (k, v) in get(prj, "weakdeps", Dict{String,Any}())]

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

    return find_unused_deps_2(;
        deps = deps,
        weakdeps = weakdeps,
        loaded_uuids = loaded_uuids,
        ignore = ignore,
    )
end

# Side-effect -free part of unused dependency analysis.
function find_unused_deps_2(;
    deps::AbstractVector{PkgId},
    weakdeps::AbstractVector{PkgId},
    loaded_uuids::AbstractVector{UUID},
    ignore::AbstractVector{Symbol},
)
    deps_uuids = [p.uuid for p in deps]
    pkgid_from_uuid = Dict(p.uuid => p for p in deps)

    unused_uuids = setdiff(deps_uuids, loaded_uuids)
    unused_pkgs = [pkgid_from_uuid[uuid] for uuid in unused_uuids]
    unused_pkgs = setdiff(unused_pkgs, weakdeps)
    unused_pkgs = [p for p in unused_pkgs if !(Symbol(p.name) in ignore)]

    return unused_pkgs
end
