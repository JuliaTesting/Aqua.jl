"""
    test_project_extras(package::Union{Module, PkgId})
    test_project_extras(packages::Vector{Union{Module, PkgId}})

Check that test target of the root project and test project
(`test/Project.toml`) are consistent.  This is useful for supporting
Julia < 1.2 while recording test-only dependency compatibility in
`test/Project.toml`.
"""
function test_project_extras(packages)
    @testset "$(result.label)" for result in analyze_project_extras(packages)
        @debug result.label result
        @test result ⊜ true
    end
end

analyze_project_extras(packages) = map(_analyze_project_extras, aspkgids(packages))

is_julia12_or_later(compat::AbstractString) = is_julia12_or_later(semver_spec(compat))
is_julia12_or_later(compat::VersionSpec) = isempty(compat ∩ semver_spec("1.0 - 1.1"))

function _analyze_project_extras(pkg::PkgId)
    label = string(pkg)

    root_project_path, found = root_project_toml(pkg)
    found || error("Unable to locate Project.toml")

    package_loc = Base.locate_package(pkg)
    package_loc === nothing &&
        return LazyTestResult(label, "Base.locate_package failed.", false)
    pkgpath = dirname(dirname(package_loc))
    test_project_path, found = project_toml_path(joinpath(pkgpath, "test"))
    if !found
        return LazyTestResult(label, "test/Project.toml file does not exist.", true)
    end
    root_project = TOML.parsefile(root_project_path)
    test_project = TOML.parsefile(test_project_path)

    # Ignore root project's extras if only supporting julia 1.2 or later.
    # See: # https://julialang.github.io/Pkg.jl/v1/creating-packages/#Test-specific-dependencies-in-Julia-1.2-and-above-1
    julia_version = get(get(root_project, "compat", Dict()), "julia", "1")
    if is_julia12_or_later(julia_version)
        return LazyTestResult(
            label,
            string(
                "Supporting only post-1.2 `julia` ($julia_version); ",
                "ignoring root project.",
            ),
            true,
        )
    end

    # `extras_deps`: test-only dependencies according to /Project.toml
    all_extras_deps = get(root_project, "extras", Dict())
    target = Set{String}(get(get(root_project, "targets", Dict()), "test", []))
    extras_deps = setdiff(
        Set{Pair{String,String}}(p for p in all_extras_deps if first(p) in target),
        Set{Pair{String,String}}(get(root_project, "deps", [])),
    )

    # `test_deps`: test-only dependencies according to /test/Project.toml:
    test_deps = setdiff(
        Set{Pair{String,String}}(get(test_project, "deps", [])),
        Set{Pair{String,String}}(get(root_project, "deps", [])),
        [root_project["name"] => root_project["uuid"]],
    )

    not_in_extras = setdiff(test_deps, extras_deps)
    not_in_test = setdiff(extras_deps, test_deps)
    if isempty(not_in_extras) && isempty(not_in_test)
        return LazyTestResult(
            label,
            """
            Root and test projects are consistent.
            Root project: $root_project_path
            Test project: $test_project_path
            """,
            true,
        )
    else
        msg = sprint() do io
            println(
                io,
                "Root and test projects should be consistent for projects supporting Julia <= 1.1.",
            )
            if !isempty(not_in_extras)
                println(io, "Test dependencies not in root project ($root_project_path):")
                for (name, uuid) in sort!(collect(not_in_extras))
                    println(io, "    $name = \"$uuid\"")
                end
            end
            if !isempty(not_in_test)
                println(io, "Dependencies not in test project ($test_project_path):")
                for (name, uuid) in sort!(collect(not_in_test))
                    println(io, "    $name = \"$uuid\"")
                end
            end
        end
        return LazyTestResult(label, msg, false)
    end
end
