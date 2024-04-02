"""
    test_project_extras(package::Union{Module, PkgId})
    test_project_extras(packages::Vector{Union{Module, PkgId}})

Check that test target of the root project and test project
(`test/Project.toml`) are consistent.  This is useful for supporting
Julia < 1.2 while recording test-only dependency compatibility in
`test/Project.toml`.
"""
function test_project_extras(pkg::PkgId; kwargs...)
    msgs = analyze_project_extras(pkg; kwargs...)
    @test isempty(msgs)
end

# Remove with next breaking version
function test_project_extras(packages::Vector{<:Union{Module,PkgId}}; kwargs...)
    @testset "$pkg" for pkg in packages
        test_project_extras(pkg; kwargs...)
    end
end

function test_project_extras(mod::Module; kwargs...)
    test_project_extras(aspkgid(mod); kwargs...)
end

is_julia12_or_later(compat::AbstractString) = is_julia12_or_later(semver_spec(compat))
is_julia12_or_later(compat::VersionSpec) = isempty(compat ∩ semver_spec("1.0 - 1.1"))

function analyze_project_extras(pkg::PkgId)
    root_project_path, found = root_project_toml(pkg)
    found || error("Unable to locate Project.toml")

    test_project_path, found =
        project_toml_path(joinpath(dirname(root_project_path), "test"))
    found || return String[] # having no test/Project.toml is fine
    root_project = TOML.parsefile(root_project_path)
    test_project = TOML.parsefile(test_project_path)

    # Ignore root project's extras if only supporting julia 1.2 or later.
    # See: # https://julialang.github.io/Pkg.jl/v1/creating-packages/#Test-specific-dependencies-in-Julia-1.2-and-above-1
    julia_version = get(get(root_project, "compat", Dict{String,Any}()), "julia", nothing)
    isnothing(julia_version) && return String["Could not find `julia` compat."]
    is_julia12_or_later(julia_version) && return String[]

    # `extras_test_deps`: test-only dependencies according to Project.toml
    deps = [PkgId(UUID(v), k) for (k, v) in get(root_project, "deps", Dict{String,Any}())]
    target =
        Set{String}(get(get(root_project, "targets", Dict{String,Any}()), "test", String[]))
    extras_test_deps = setdiff(
        [
            PkgId(UUID(v), k) for
            (k, v) in get(root_project, "extras", Dict{String,Any}()) if k in target
        ],
        deps,
    )

    # `test_deps`: test-only dependencies according to test/Project.toml:
    test_deps = setdiff(
        [PkgId(UUID(v), k) for (k, v) in get(test_project, "deps", Dict{String,Any}())],
        deps,
        [PkgId(UUID(root_project["uuid"]), root_project["name"])],
    )

    not_in_extras = setdiff(test_deps, extras_test_deps)
    not_in_test = setdiff(extras_test_deps, test_deps)
    if isempty(not_in_extras) && isempty(not_in_test)
        return String[]
    else
        msgs = String[]
        push!(
            msgs,
            "Root and test projects should be consistent for projects supporting Julia <= 1.1.",
        )
        if !isempty(not_in_extras)
            msg = "Test dependencies not in root project ($root_project_path):"
            for pkg in sort!(collect(not_in_extras); by = (pkg -> pkg.name))
                msg *= "\n\t$(pkg.name) [$(pkg.uuid)]"
            end
            push!(msgs, msg)
        end
        if !isempty(not_in_test)
            msg = "Dependencies not in test project ($test_project_path):"
            for pkg in sort!(collect(not_in_test); by = (pkg -> pkg.name))
                msg *= "\n\t$(pkg.name) [$(pkg.uuid)]"
            end
            push!(msgs, msg)
        end

        return msgs
    end
end
