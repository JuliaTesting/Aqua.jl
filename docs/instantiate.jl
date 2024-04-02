# This script can be used to quickly instantiate the docs/Project.toml environment.
using Pkg, TOML

package_directory = joinpath(@__DIR__, "..")
docs_directory = isempty(ARGS) ? @__DIR__() : joinpath(pwd(), ARGS[1])
cd(docs_directory) do
    Pkg.activate(docs_directory)
    Pkg.develop(PackageSpec(path = package_directory))
    Pkg.instantiate()

    # Remove Aqua again from docs/Project.toml
    lines = readlines(joinpath(docs_directory, "Project.toml"))
    open(joinpath(docs_directory, "Project.toml"), "w") do io
        for line in lines
            if line == "Aqua = \"4c88cf16-eb10-579e-8560-4a9242c79595\""
                continue
            end
            println(io, line)
        end
    end
end
