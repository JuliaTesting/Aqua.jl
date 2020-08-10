"""
    Aqua.test_project_toml_formatting(packages)
"""
function test_project_toml_formatting(packages)
    @testset "$(result.label)" for result in analyze_project_toml_formatting(packages)
        @debug result.label result
        @test result ⊜ true
    end
end

analyze_project_toml_formatting(packages) =
    [_analyze_project_toml_formatting_1(path) for path in project_toml_files_in(packages)]

project_toml_files_in(path::AbstractString) = [path]
project_toml_files_in(m::Module) = project_toml_files_in(PkgId(m))
function project_toml_files_in(pkg::PkgId)
    srcpath = Base.locate_package(pkg)
    if srcpath === nothing
        # TODO: record this as a test failure?
        error("Package file and directory not found: $pkg")
    end
    dir = dirname(dirname(srcpath))
    paths = [project_toml_path(dir)[1]]
    p, found = project_toml_path(joinpath(dir, "test"))
    found && push!(paths, p)
    return paths
end

project_toml_files_in(iterable) =
    [path for x in iterable for path in project_toml_files_in(x)]

function _analyze_project_toml_formatting_1(path::AbstractString)
    label = path

    if !isfile(path)
        return LazyTestResult(label, "Path `$path` is not an existing file.", false)
    end

    original = read(path, String)
    return _analyze_project_toml_formatting_2(path, original)
end

function _analyze_project_toml_formatting_2(path::AbstractString, original)
    @debug "Checking TOML style: `$path`" Text(original)
    label = path

    prj = TOML.parse(original)
    formatted = sprint(print_project, prj)
    if original == formatted
        LazyTestResult(
            label,
            "Running `Pkg.resolve` on `$(path)` did not change the content.",
            true,
        )
    else
        diff = format_diff(
            "Original $(basename(path))" => original,
            "Pkg's output" => formatted,
        )
        LazyTestResult(
            label,
            """
            Running `Pkg.resolve` on `$(path)` will change the content.

            $diff
            """,
            false,
        )
    end
end
