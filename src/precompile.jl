using PrecompileTools: @compile_workload

# Create a minimal fake package to test
module _FakePackage
export fake_function
fake_function() = 1
end

@compile_workload begin
    redirect_stdout(devnull) do
        test_all(
            _FakePackage;
            ambiguities = false,
            project_extras = false,
            stale_deps = false,
            deps_compat = false,
            persistent_tasks = false)
    end

    # Explicitly precompile the tests that need a real package module
    precompile(test_ambiguities, (Vector{Module},))
    precompile(test_project_extras, (Module,))
    precompile(test_stale_deps, (Module,))
    precompile(test_deps_compat, (Module,))

    # Create a fake package directory for testing persistent_tasks. We go to
    # some effort to precompile this because it takes the longest due to Pkg
    # calls and running precompilation in a subprocess.
    mktempdir() do dir
        project_file = joinpath(dir, "Project.toml")
        write(project_file, """
            name = "AquaFakePackage"
            uuid = "5a23b2e7-8c45-4b1c-9d3f-7a6b4c8d9e0f"
            version = "0.1.0"

            [deps]
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

            [compat]
            Test = "1"
            julia = "1"
            """)

        srcdir = joinpath(dir, "src")
        mkdir(srcdir)
        write(joinpath(srcdir, "AquaFakePackage.jl"), "module AquaFakePackage end")

        # The meat of the compilation latency comes from this function. Running
        # test_persistent_tasks() directly is more difficult because it takes a
        # Module and then gets the package directory, and we don't want to load
        # the fake package.
        precompile_wrapper(project_file, 10, quote end)
    end
end
