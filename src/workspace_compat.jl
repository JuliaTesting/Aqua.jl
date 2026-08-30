"""
    Aqua.test_workspace_compat(package)

Test that, when `test/Project.toml` is a member of the root project's
workspace, it does not declare a `[compat]` entry for any name the root
`Project.toml` already owns.

Workspace members share a single manifest, and `Pkg` *intersects* the compat
bounds declared by every member when resolving it. A bound repeated in
`test/Project.toml` therefore silently narrows the resolve: the root's declared
bound stops being the effective one, and nothing warns about it. Automated
dependency updates introduce exactly this when the update job is rooted at
`test/`, because they synthesize a compat entry for every direct dependency
that lacks one.

Bounds for genuinely test-only dependencies (`Aqua`, `Test`, ...) are
legitimate and are not flagged: only names the root project already owns are
reported, that is, its `deps`, its `weakdeps`, anything it lists in `[compat]`
(including `julia`), and the package's own name.

The test is a no-op unless the root `Project.toml` declares `test` as a
workspace member, e.g.

```toml
[workspace]
projects = ["test"]
```

Outside a workspace the test project resolves into its own manifest, where a
repeated bound constrains only the test environment.

# Arguments
- `package`: a top-level `Module` or a `Base.PkgId`.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of `@test`.
- `ignore::AbstractVector{Symbol} = Symbol[]`: names of packages to be ignored.
"""
function test_workspace_compat(pkg::PkgId; broken::Bool = false, kwargs...)
    result = find_workspace_compat_conflicts(pkg; kwargs...)
    if broken
        @test_broken isempty(result)
    else
        # Comparing against `String[]` makes the failure output name the offenders.
        @test result == String[]
    end
end

function test_workspace_compat(mod::Module; kwargs...)
    test_workspace_compat(aspkgid(mod); kwargs...)
end

# Normalize a `[workspace] projects` entry so that "test", "./test" and
# "test/" all compare equal.
function normalize_workspace_path(path::AbstractString)
    normalized = replace(String(path), '\\' => '/')
    startswith(normalized, "./") && (normalized = normalized[3:end])
    return String(rstrip(normalized, '/'))
end

# Whether the project `prj` declares `test` as one of its workspace members.
function declares_test_workspace(prj::Dict{String,Any})
    workspace = get(prj, "workspace", nothing)
    workspace isa AbstractDict || return false
    projects = get(workspace, "projects", nothing)
    projects isa AbstractVector || return false
    return any(p -> p isa AbstractString && normalize_workspace_path(p) == "test", projects)
end

# Names whose version bounds belong to the root project `prj`: its
# dependencies, its weak dependencies, anything it already pins in `[compat]`
# (including `julia`), and the package itself.
function root_owned_names(prj::Dict{String,Any})
    owned = Set{String}()
    union!(owned, keys(get(prj, "deps", Dict{String,Any}())))
    union!(owned, keys(get(prj, "weakdeps", Dict{String,Any}())))
    union!(owned, keys(get(prj, "compat", Dict{String,Any}())))
    name = get(prj, "name", nothing)
    name isa AbstractString && push!(owned, String(name))
    return owned
end

function find_workspace_compat_conflicts(
    root_prj::Dict{String,Any},
    test_prj::Dict{String,Any};
    ignore::AbstractVector{Symbol} = Symbol[],
)
    declares_test_workspace(root_prj) || return String[]
    test_compat = keys(get(test_prj, "compat", Dict{String,Any}()))
    ignored = Set{String}(String(name) for name in ignore)
    return sort!(
        String[
            name for
            name in intersect(test_compat, root_owned_names(root_prj)) if !(name in ignored)
        ],
    )
end

function find_workspace_compat_conflicts(pkg::PkgId; kwargs...)
    root_project_path, found = root_project_toml(pkg)
    found || error("Unable to locate Project.toml")

    test_project_path, found =
        project_toml_path(joinpath(dirname(root_project_path), "test"))
    found || return String[] # having no test/Project.toml is fine

    root_prj = TOML.parsefile(root_project_path)
    test_prj = TOML.parsefile(test_project_path)
    conflicts = find_workspace_compat_conflicts(root_prj, test_prj; kwargs...)

    if !isempty(conflicts)
        printstyled(
            stderr,
            "$pkg declares a compat entry in $test_project_path for the following names already owned by the root project:\n";
            bold = true,
            color = Base.error_color(),
        )
        root_compat = get(root_prj, "compat", Dict{String,Any}())
        test_compat = get(test_prj, "compat", Dict{String,Any}())
        for name in conflicts
            root_bound = get(root_compat, name, nothing)
            root_desc = if root_bound === nothing
                "the root project lists it without a compat entry"
            else
                "the root project declares $(repr(root_bound))"
            end
            println(stderr, "\t$name = $(repr(test_compat[name]))\t($root_desc)")
        end
        println(
            stderr,
            "Workspace members share a single manifest, so these bounds are intersected and silently narrow the root's. Remove them from $test_project_path.",
        )
    end

    return conflicts
end
