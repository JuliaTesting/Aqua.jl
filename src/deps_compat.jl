"""
    Aqua.test_deps_compat(package)

Test that the `Project.toml` of `package` has a `compat` entry for
each package listed under `deps`.

# Arguments
- `packages`: a top-level `Module`, a `Base.PkgId`, or a collection of
  them.

# Keyword Arguments
## Test choosers
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
function test_deps_compat(pkg::PkgId; check_extras = true, check_weakdeps = true, kwargs...)
    @testset "$pkg deps" begin
        test_deps_compat(pkg, "deps"; kwargs...)
    end
    if check_extras !== false
        @testset "$pkg extras" begin
            result = test_deps_compat(pkg, "extras"; askwargs(check_extras)...)
        end
    end
    if check_weakdeps !== false
        @testset "$pkg weakdeps" begin
            result = test_deps_compat(pkg, "weakdeps"; askwargs(check_weakdeps)...)
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

function find_missing_deps_compat(pkg::PkgId, deps_type::String = "deps"; kwargs...)
    result = root_project_or_failed_lazytest(pkg)
    result isa LazyTestResult && error("Unable to locate Project.toml")
    root_project_path = result
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

    stdlibs = get_stdlib_list()
    missing_compat = sort!(
        [
            d for d in map(d -> PkgId(UUID(last(d)), first(d)), collect(deps)) if
            !(d.name in keys(compat)) && !(d in stdlibs) && !(d.name in String.(ignore))
        ];
        by = (pkg -> pkg.name),
    )
    return missing_compat
end
