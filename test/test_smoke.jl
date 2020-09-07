module TestSmoke

using Aqua
Aqua.test_all(Aqua)
Aqua.test_all(
    Aqua;
    ambiguities = false,
    unbound_args = false,
    undefined_exports = false,
    stale_deps = true,
    deps_compat = true,
    project_toml_formatting = true,
)

end  # module
