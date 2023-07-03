"""
    Aqua.test_project_toml_formatting(packages)
"""
function test_project_toml_formatting(packages)
    @testset "$(result.label)" for result in
                                   ProjectTomlFormatting.analyze_project_toml_formatting(
        packages,
    )
        @debug result.label result
        @test result ⊜ true
    end
end

module ProjectTomlFormatting

using Base: PkgId
using Pkg: TOML

using Aqua: LazyTestResult, format_diff, project_toml_path

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
    p, found = project_toml_path(joinpath(dir, "docs"))
    found && push!(paths, p)
    p, found = project_toml_path(joinpath(dir, "test"))
    found && push!(paths, p)
    return paths
end

project_toml_files_in(iterable) =
    [path for x in iterable for path in project_toml_files_in(x)]

const _project_key_order = [
    "name",
    "uuid",
    "keywords",
    "license",
    "desc",
    "deps",
    "weakdeps",
    "extensions",
    "compat",
    "extras",
    "targets",
]

print_project(io, dict) =
    TOML.print(io, dict, sorted = true, by = key -> (project_key_order(key), key))

project_key_order(key::String) =
    something(findfirst(x -> x == key, _project_key_order), length(_project_key_order) + 1)

splitlines(str; kwargs...) = readlines(IOBuffer(str); kwargs...)

analyze_project_toml_formatting(packages) =
    [analyze_project_toml_formatting_1(path) for path in project_toml_files_in(packages)]

function analyze_project_toml_formatting_1(path::AbstractString)
    label = path

    if !isfile(path)
        return LazyTestResult(label, "Path `$path` is not an existing file.", false)
    end

    original = read(path, String)
    return analyze_project_toml_formatting_2(path, original)
end

function analyze_project_toml_formatting_2(path::AbstractString, original)
    @debug "Checking TOML style: `$path`" Text(original)
    label = path

    prj = TOML.parse(original)
    formatted = sprint(print_project, prj)
    if splitlines(original) == splitlines(formatted)
        LazyTestResult(label, "The file `$(path)` is in canonical format.", true)
    else
        diff = format_diff(
            "Original $(basename(path))" => original,
            "Pkg's output" => formatted,
        )
        LazyTestResult(
            label,
            """
            The file `$(path)` is not in canonical format.

            $diff
            """,
            false,
        )
    end
end

end # module
