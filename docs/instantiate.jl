# This script can be used to quickly instantiate the docs/Project.toml environment.
using Pkg, TOML

package_directory = joinpath(@__DIR__, "..")
docs_directory = isempty(ARGS) ? @__DIR__() : joinpath(pwd(), ARGS[1])
cd(docs_directory) do
    Pkg.activate(docs_directory)
    Pkg.develop(PackageSpec(path = package_directory))
    Pkg.instantiate()

    # Remove Aqua again from docs/Project.toml
    project_toml = TOML.parsefile(joinpath(docs_directory, "Project.toml"))
    delete!(project_toml["deps"], "Aqua")
    open(joinpath(docs_directory, "Project.toml"), "w") do io
        TOML.print(io, project_toml)
    end
end
