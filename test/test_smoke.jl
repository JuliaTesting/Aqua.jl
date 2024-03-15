module TestSmoke

using Aqua

# test defaults
Aqua.test_all(
    Aqua;
    unused_deps = (; ignore = [:Compat]),  # conditionally loaded
)

# test everything else
Aqua.test_all(
    Aqua;
    ambiguities = false,
    unbound_args = false,
    undefined_exports = false,
    project_extras = false,
    unused_deps = false,
    deps_compat = false,
    piracies = false,
    persistent_tasks = false,
)

end  # module
