# Release notes

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## Unreleased

### Changed

- Use [Changelog.jl](https://github.com/JuliaDocs/Changelog.jl) to generate the changelog, and add it to the documentation. ([#277], [#279])
- `test_project_extras` prints failures the same on all julia versions. In particular, 1.11 and nightly are no outliers. ([#275])


## Version [v0.8.4] - 2023-12-01

### Added

- `test_persistent_tasks` now accepts an optional `expr` to run in the precompile package. ([#255])
  + The `expr` option lets you test whether your precompile script leaves any dangling Tasks
  or Timers, which would make it unsafe to use as a dependency for downstream packages.


## Version [v0.8.3] - 2023-11-29

### Changed

- `test_persistent_tasks` is now less noisy. ([#256])
- Completely overhauled the documentation. Every test now has its dedicated page. ([#250])


## Version [v0.8.2] - 2023-11-16

### Changed

- `test_persistent_tasks` no longer clears the environment of the subtask. Instead, it modifies `LOAD_PATH` directly to make stdlibs work. ([#241])


## Version [v0.8.1] - 2023-11-16

### Changed

- `test_persistent_tasks` now redirects stdout and stderr of the created subtask. Furthermore, the environment of the subtask gets cleared to allow default values for `JULIA_LOAD_PATH` to work. ([#240])


## Version [v0.8.0] - 2023-11-15

### Added

- Two additions check whether packages might block precompilation on Julia 1.10 or higher: ([#174])
  + `test_persistent_tasks` tests whether "your" package can safely be used as a dependency for downstream packages. This test is enabled for the default testsuite `test_all`, but you can opt-out by supplying `persistent_tasks=false` to `test_all`. [BREAKING]
  + `find_persistent_tasks_deps` is useful if "your" package hangs upon precompilation: it runs `test_persistent_tasks` on all the things you depend on, and may help isolate the culprit(s).

### Changed

- In `test_deps_compat`, the two subtests `check_extras` and `check_weakdeps` are now run by default. ([#202]) [BREAKING]
- `test_deps_compat` now requires compat entries for all dependencies. Stdlibs no longer get ignored. This change is motivated by similar changes in the General registry. ([#215]) [BREAKING]
- `test_ambiguities` now excludes the keyword sorter of all `exclude`d functions with keyword arguments as well. ([#203])
- `test_piracy` is renamed to `test_piracies`. ([#230]) [BREAKING]
- `test_ambiguities` and `test_piracies` now return issues in a defined order. This order may change in a patch release of Aqua.jl. ([#233])
- Improved the message for `test_project_extras` failures. ([#234])
- `test_deps_compat` now requires a compat entry for `julia` This can be disabling by setting `compat_julia = false`. ([#236]) [BREAKING]

### Removed

- `test_project_toml_formatting` has been removed. Thus, the kwarg `project_toml_formatting` to `test_all` no longer exists. ([#209]) [BREAKING]


## Version [v0.7.4] - 2023-10-24

### Added

- `test_deps_compat` has two new kwargs `check_extras` and `check_weakdeps` to extend the test to these dependency categories. They are not run by default. ([#200])

### Changed

- The docstring for `test_stale_deps` explains the situation with package extensions. ([#203])
- The logo of Aqua.jl has been updated. ([#128])


## Version [v0.7.3] - 2023-09-25

### Added

- `test_deps_compat` has a new kwarg `broken` to mark the test as broken using `Test.@test_broken`. ([#193])

### Fixed

- `test_piracy` no longer prints warnings for methods where the third argument is a `TypeVar`. ([#188])


## Version [v0.7.2] - 2023-09-19

### Changed

- `test_undefined_exports` additionally prints the modules of the undefined exports in the failure report. ([#177])


## Version [v0.7.1] - 2023-09-05

### Fixed

- `test_piracy` no longer reports type piracy in the kwsorter, i.e. `kwcall` should no longer appear in the report. ([#171])


## Version [v0.7.0] - 2023-08-29

### Added

- Installation and usage instructions to the documentation. ([#159])

### Changed

- `test_ambiguities` now allows to exclude non-singleton callables. Excluding a type means to exclude all methods of the callable (sometimes also called "functor") and the constructor. ([#144]) [BREAKING]
- `test_piracy` considers more functions. Callables and qualified names are now also checked. ([#156]) [BREAKING]

### Fixed

- `test_ambiguities` prints less unnecessary whitespace. ([#158])
- `test_ambiguities` no longer hangs indefinitely when there are many ambiguities. ([#166])


## Version [v0.6.7] - 2023-09-19

### Changed

- `test_undefined_exports` additionally prints the modules of the undefined exports in the failure report. ([#177])

### Fixed

- `test_ambiguities` prints less unnecessary whitespace. ([#158])
- Fix `test_piracy` for some methods with arguments of custom subtypes of `Function`. ([#170])


## Version [v0.6.6] - 2023-08-24

### Fixed

- `test_ambiguities` no longer hangs indefinitely when there are many ambiguities. ([#166])


## Version [v0.6.5] - 2023-06-26

### Fixed

- Typo when calling kwargs. ([#153])


## Version [v0.6.4] - 2023-06-25

### Added

- `test_piracy` has a new kwarg `treat_as_own`. It is useful for testing packages that deliberately commit some type piracy, e.g. modules adding higher-level functionality to a lightweight C-wrapper, or packages that are extending `StatsAPI.jl`. ([#140])

### Changed

- Explanation of `test_unbound_args` in the docstring. ([#146])

### Fixed

- Callable objects with type parameters no longer error in `test_ambiguities`' kwarg `exclude`. ([#142])


## Version [v0.6.3] - 2023-06-05

### Changed

- When installing a method for a union type, it is only reported by `test_piracy` if *all* types in the union are foreign (instead of *any* for arguments). ([#131])

### Fixed

- `test_deps_compat`'s kwarg `ignore` now works as intended. ([#130])
- Weakdeps are not reported as stale by `test_stale_deps` anymore. ([#135])


## Version [v0.6.2] - 2023-06-02

### Added

- `test_ambiguities`, `test_undefined_exports`, `test_piracy`, and `test_unbound_args` each have a new kwarg `broken` to mark the test as broken using `Test.@test_broken`. ([#124])

### Changed

- `test_piracy` now prints the offending methods in a more readable way. ([#93])
- Extend `test_project_toml_formatting` to `docs/Project.toml`. ([#115])

### Fixed

- `test_stale_deps` no longer fails if any of the loaded packages prints during loading. ([#113])
- Clarified the error message of `test_unbound_args`. ([#103])
- Clarified the error message of `test_project_toml_formatting`. ([#122])


<!-- Links generated by Changelog.jl -->

[v0.6.2]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.6.2
[v0.6.3]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.6.3
[v0.6.4]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.6.4
[v0.6.5]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.6.5
[v0.6.6]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.6.6
[v0.6.7]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.6.7
[v0.7.0]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.7.0
[v0.7.1]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.7.1
[v0.7.2]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.7.2
[v0.7.3]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.7.3
[v0.7.4]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.7.4
[v0.8.0]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.8.0
[v0.8.1]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.8.1
[v0.8.2]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.8.2
[v0.8.3]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.8.3
[v0.8.4]: https://github.com/JuliaTesting/Aqua.jl/releases/tag/v0.8.4
[#93]: https://github.com/JuliaTesting/Aqua.jl/issues/93
[#103]: https://github.com/JuliaTesting/Aqua.jl/issues/103
[#113]: https://github.com/JuliaTesting/Aqua.jl/issues/113
[#115]: https://github.com/JuliaTesting/Aqua.jl/issues/115
[#122]: https://github.com/JuliaTesting/Aqua.jl/issues/122
[#124]: https://github.com/JuliaTesting/Aqua.jl/issues/124
[#128]: https://github.com/JuliaTesting/Aqua.jl/issues/128
[#130]: https://github.com/JuliaTesting/Aqua.jl/issues/130
[#131]: https://github.com/JuliaTesting/Aqua.jl/issues/131
[#135]: https://github.com/JuliaTesting/Aqua.jl/issues/135
[#140]: https://github.com/JuliaTesting/Aqua.jl/issues/140
[#142]: https://github.com/JuliaTesting/Aqua.jl/issues/142
[#144]: https://github.com/JuliaTesting/Aqua.jl/issues/144
[#146]: https://github.com/JuliaTesting/Aqua.jl/issues/146
[#153]: https://github.com/JuliaTesting/Aqua.jl/issues/153
[#156]: https://github.com/JuliaTesting/Aqua.jl/issues/156
[#158]: https://github.com/JuliaTesting/Aqua.jl/issues/158
[#159]: https://github.com/JuliaTesting/Aqua.jl/issues/159
[#166]: https://github.com/JuliaTesting/Aqua.jl/issues/166
[#170]: https://github.com/JuliaTesting/Aqua.jl/issues/170
[#171]: https://github.com/JuliaTesting/Aqua.jl/issues/171
[#174]: https://github.com/JuliaTesting/Aqua.jl/issues/174
[#177]: https://github.com/JuliaTesting/Aqua.jl/issues/177
[#188]: https://github.com/JuliaTesting/Aqua.jl/issues/188
[#193]: https://github.com/JuliaTesting/Aqua.jl/issues/193
[#200]: https://github.com/JuliaTesting/Aqua.jl/issues/200
[#202]: https://github.com/JuliaTesting/Aqua.jl/issues/202
[#203]: https://github.com/JuliaTesting/Aqua.jl/issues/203
[#209]: https://github.com/JuliaTesting/Aqua.jl/issues/209
[#215]: https://github.com/JuliaTesting/Aqua.jl/issues/215
[#230]: https://github.com/JuliaTesting/Aqua.jl/issues/230
[#233]: https://github.com/JuliaTesting/Aqua.jl/issues/233
[#234]: https://github.com/JuliaTesting/Aqua.jl/issues/234
[#236]: https://github.com/JuliaTesting/Aqua.jl/issues/236
[#240]: https://github.com/JuliaTesting/Aqua.jl/issues/240
[#241]: https://github.com/JuliaTesting/Aqua.jl/issues/241
[#250]: https://github.com/JuliaTesting/Aqua.jl/issues/250
[#255]: https://github.com/JuliaTesting/Aqua.jl/issues/255
[#256]: https://github.com/JuliaTesting/Aqua.jl/issues/256
[#275]: https://github.com/JuliaTesting/Aqua.jl/issues/275
[#277]: https://github.com/JuliaTesting/Aqua.jl/issues/277
