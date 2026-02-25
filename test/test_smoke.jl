module TestSmoke

using Aqua

# test defaults

# TODO: fix instead of ignoring
private_explicit_imports_aqua = (:PkgId,) # Base
private_explicit_imports_aquapiracy = (:is_in_mods,) # Test
private_qualified_accesses_aqua = (
    :JLOptions, # Base
    :PkgId, # Base
    :SIGKILL, # Base
    :error_color, # Base
    :eval, # Base
    :isbindingresolved, # Base
    :isdeprecated, # Base
    :julia_cmd, # Base
    :kwcall, # Core
    :kwftype, # Core
    :load_path_setup_code, # Base
    :morespecific, # Base
    :require, # Base
    :respect_sysimage_versions, # Pkg
    :show_tuple_as_call, # Base
    :unwrap_unionall, # Base,
)
private_qualified_accesses_aquapiracy = (
    :MethodTable, # Core
    :TypeofVararg, # Core
    :loaded_modules_array, # Base
    :methodtable, # Core
    :uniontypes, # Base
    :visit, # Base
)

explicit_imports_param_for_aqua = @static if VERSION < v"1.12"
    false  # some symbols were only made public in more recent versions of Julia, the list above is for 1.12
else
    (;
        all_explicit_imports_are_public = (;
            ignore = (
                private_explicit_imports_aqua...,
                private_explicit_imports_aquapiracy...,
            )
        ),
        all_qualified_accesses_are_public = (;
            ignore = (
                private_qualified_accesses_aqua...,
                private_qualified_accesses_aquapiracy...,
            )
        ),
    )
end

Aqua.test_all(Aqua; explicit_imports = explicit_imports_param_for_aqua)

# test everything else
Aqua.test_all(
    Aqua;
    ambiguities = false,
    unbound_args = false,
    undefined_exports = false,
    project_extras = false,
    stale_deps = false,
    deps_compat = false,
    piracies = false,
    persistent_tasks = false,
    undocumented_names = false,
    explicit_imports = false,
)

end  # module
