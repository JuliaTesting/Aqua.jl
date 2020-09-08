"""
    Aqua.test_deps_compat(package)

Test that `Project.toml` of `package` list all `compat` for `deps`.

# Arguments
- `packages`: a top-level `Module`, a `Base.PkgId`, or a collection of
  them.
"""
test_deps_compat
function test_deps_compat(packages)
    @testset "$(result.label)" for result in analyze_deps_compat(packages)
        @debug result.label result
        @test result ⊜ true
    end
end

analyze_deps_compat(packages) = [_analyze_deps_compat_1(pkg) for pkg in aspkgids(packages)]

function _analyze_deps_compat_1(pkg::PkgId)
    result = root_project_or_failed_lazytest(pkg)
    result isa LazyTestResult && return result
    root_project_path = result
    return _analyze_deps_compat_2(pkg, root_project_path, TOML.parsefile(root_project_path))
end

function _analyze_deps_compat_2(pkg::PkgId, root_project_path, prj)
    label = "$pkg"

    deps = get(prj, "deps", nothing)
    if deps === nothing
        return LazyTestResult(label, "`$root_project_path` does not have `deps`", true)
    end
    compat = get(prj, "compat", nothing)
    if compat === nothing
        return LazyTestResult(label, "`$root_project_path` does not have `compat`", false)
    end

    stdlib_name_from_uuid = stdlibs()
    stdlib_deps = filter!(
        !isnothing,
        [get(stdlib_name_from_uuid, UUID(uuid), nothing) for (_, uuid) in deps],
    )
    missing_compat = setdiff(setdiff(keys(deps), keys(compat)), stdlib_deps)
    if !isempty(missing_compat)
        msg = join(
            [
                "`$root_project_path` does not specify `compat` for:"
                sort!(collect(missing_compat))
            ],
            "\n",
        )
        return LazyTestResult(label, msg, false)
    end

    return LazyTestResult(
        label,
        "`$root_project_path` specifies `compat` for all `deps`",
        true,
    )
end
