"""
    Aqua.test_deps_compat(package; [ignore])

Test that `Project.toml` of `package` list all `compat` for `deps`.

# Arguments
- `packages`: a top-level `Module`, a `Base.PkgId`, or a collection of
  them.

# Keyword Arguments
- `ignore::Vector{Symbol}`: names of dependent packages to be ignored.
"""
function test_deps_compat(packages; kwargs...)
    @testset "$(result.label)" for result in
                                   DepsCompat.analyze_deps_compat(packages; kwargs...)
        @debug result.label result
        @test result ⊜ true
    end
end

module DepsCompat

using Base: PkgId, UUID
using Pkg: TOML

using ..Aqua: LazyTestResult, aspkgids, isnothing, root_project_or_failed_lazytest, stdlibs

function analyze_deps_compat(packages; kwargs...)
    package_ids = aspkgids(packages)::Vector{PkgId}
    return analyze_deps_compat(package_ids; kwargs...)
end

function analyze_deps_compat(packages::Vector{PkgId}; kwargs...)
    result = [_analyze_deps_compat_1(pkg; kwargs...) for pkg in packages]
    return result
end

function _analyze_deps_compat_1(pkg::PkgId; kwargs...)
    result = root_project_or_failed_lazytest(pkg)
    result isa LazyTestResult && return result
    root_project_path = result
    return _analyze_deps_compat_2(
        pkg,
        root_project_path,
        TOML.parsefile(root_project_path);
        kwargs...,
    )
end

# For supporting Julia 1.8-DEV and above which give us a tuple instead of a string
_unwrap_name(x::Tuple) = first(x)
_unwrap_name(x::String) = x
_unwrap_name(x::Nothing) = x
function _analyze_deps_compat_2(
    pkg::PkgId,
    root_project_path,
    prj;
    ignore::AbstractVector{Symbol} = Symbol[],
)
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
        [
            _unwrap_name(get(stdlib_name_from_uuid, UUID(uuid), nothing)) for
            (_, uuid) in deps
        ],
    )
    missing_compat =
        setdiff(setdiff(setdiff(keys(deps), keys(compat)), stdlib_deps), String.(ignore))
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

end # module
