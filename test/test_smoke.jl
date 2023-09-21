module TestSmoke

using Aqua

# test defaults
Aqua.test_all(Aqua;)

# test everything else
Aqua.test_all(
    Aqua;
    ambiguities = false,
    unbound_args = false,
    undefined_exports = false,
    project_extras = false,
    stale_deps = false,
    deps_compat = (; check_extras = true, check_weakdeps = true),
    project_toml_formatting = false,
    piracy = false,
    persistent_tasks = true,
)

end  # module
