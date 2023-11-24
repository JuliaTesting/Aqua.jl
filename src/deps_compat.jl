"""
    Aqua.test_deps_compat(package)

Test that the `Project.toml` of `package` has a `compat` entry for
each package listed under `deps` and for `julia`.

# Arguments
- `packages`: a top-level `Module`, a `Base.PkgId`, or a collection of
  them.

# Keyword Arguments
## Test choosers
- `check_julia = true`: If true, additionally check for a compat entry for "julia".
- `check_extras = true`: If true, additionally check "extras". A NamedTuple
  can be used to pass keyword arguments with test options (see below).
- `check_weakdeps = true`: If true, additionally check "weakdeps". A NamedTuple
  can be used to pass keyword arguments with test options (see below).

## Test options
If these keyword arguments are set directly, they only apply to the standard test
for "deps". To apply them to "extras" and "weakdeps", pass them as a NamedTuple
to the corresponding `check_\$x` keyword argument.
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test` for "deps".
- `ignore::Vector{Symbol}`: names of dependent packages to be ignored.
"""
function test_deps_compat(
    pkg::PkgId;
    check_julia = true,
    check_extras = true,
    check_weakdeps = true,
    kwargs...,
)
    if check_julia !== false
        @testset "julia" begin
            isempty(askwargs(check_julia)) || error("Keyword arguments not supported")
            test_julia_compat(pkg)
        end
    end
    @testset "$pkg deps" begin
        test_deps_compat(pkg, "deps"; kwargs...)
    end
    if check_extras !== false
        @testset "$pkg extras" begin
            test_deps_compat(pkg, "extras"; askwargs(check_extras)...)
        end
    end
    if check_weakdeps !== false
        @testset "$pkg weakdeps" begin
            test_deps_compat(pkg, "weakdeps"; askwargs(check_weakdeps)...)
        end
    end
end

function test_deps_compat(pkg::PkgId, deps_type::String; broken::Bool = false, kwargs...)
    result = find_missing_deps_compat(pkg, deps_type; kwargs...)
    if broken
        @test_broken isempty(result)
    else
        @test isempty(result)
    end
end

# Remove with next breaking version
function test_deps_compat(packages::Vector{<:Union{Module,PkgId}}; kwargs...)
    @testset "$pkg" for pkg in packages
        test_deps_compat(pkg; kwargs...)
    end
end

function test_deps_compat(mod::Module; kwargs...)
    test_deps_compat(aspkgid(mod); kwargs...)
end

function test_julia_compat(pkg::PkgId; broken::Bool = false)
    if broken
        @test_broken has_julia_compat(pkg)
    else
        @test has_julia_compat(pkg)
    end
end

function has_julia_compat(pkg::PkgId)
    root_project_path, found = root_project_toml(pkg)
    found || error("Unable to locate Project.toml")
    prj = TOML.parsefile(root_project_path)
    return has_julia_compat(prj)
end

function has_julia_compat(prj::Dict{String,Any})
    return "julia" in keys(get(prj, "compat", Dict{String,Any}()))
end

function find_missing_deps_compat(pkg::PkgId, deps_type::String = "deps"; kwargs...)
    root_project_path, found = root_project_toml(pkg)
    found || error("Unable to locate Project.toml")
    missing_compat =
        find_missing_deps_compat(TOML.parsefile(root_project_path), deps_type; kwargs...)

    if !isempty(missing_compat)
        printstyled(
            stderr,
            "$pkg does not declare a compat entry for the following $deps_type:\n";
            bold = true,
            color = Base.error_color(),
        )
        show(stderr, MIME"text/plain"(), missing_compat)
        println(stderr)
    end

    return missing_compat
end

function find_missing_deps_compat(
    prj::Dict{String,Any},
    deps_type::String;
    ignore::AbstractVector{Symbol} = Symbol[],
)
    deps = get(prj, deps_type, Dict{String,Any}())
    compat = get(prj, "compat", Dict{String,Any}())

    missing_compat = sort!(
        [
            d for d in map(d -> PkgId(UUID(last(d)), first(d)), collect(deps)) if
            !(d.name in keys(compat)) && !(d.name in String.(ignore))
        ];
        by = (pkg -> pkg.name),
    )
    return missing_compat
end
