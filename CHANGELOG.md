# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- The minimum requirement for julia was raised from `1.0` to `1.4`. ([#221](https://github.com/JuliaTesting/Aqua.jl/pull/221))
- In `test_deps_compat`, the two subtests `check_extras` and `check_weakdeps` are now run by default. ([#202](https://github.com/JuliaTesting/Aqua.jl/pull/202)) [BREAKING]
- `test_deps_compat` now reqiures compat entries for all dependencies. Stdlibs no longer get ignored. This change is motivated by similar changes in the General registry. ([#215](https://github.com/JuliaTesting/Aqua.jl/pull/215)) [BREAKING]


## [0.7.4] - 2023-10-24

### Added

- `test_deps_compat` has two new kwargs `check_extras` and `check_weakdeps` to extend the test to these dependency categories. They are not run by default. ([#200](https://github.com/JuliaTesting/Aqua.jl/pull/200))

### Changed

- The docstring for `test_stale_deps` explains the situation with package extensions. ([#203](https://github.com/JuliaTesting/Aqua.jl/pull/203))
- The logo of Aqua.jl has been updated. ([#128](https://github.com/JuliaTesting/Aqua.jl/pull/128))


## [0.7.3] - 2023-09-25

### Added

- `test_deps_compat` has a new kwarg `broken` to mark the test as broken using `Test.@test_broken`. ([#193](https://github.com/JuliaTesting/Aqua.jl/pull/193))

### Fixed

- `test_piracy` no longer prints warnings for methods where the third argument is a `TypeVar`. ([#188](https://github.com/JuliaTesting/Aqua.jl/pull/188))


## [0.7.2] - 2023-09-19

### Changed

- `test_undefined_exports` additionally prints the modules of the undefined exports in the failure report. ([#177](https://github.com/JuliaTesting/Aqua.jl/pull/177))


## [0.7.1] - 2023-09-05

### Fixed

- `test_piracy` no longer reports type piracy in the kwsorter, i.e. `kwcall` should no longer appear in the report. ([#171](https://github.com/JuliaTesting/Aqua.jl/pull/171))


## [0.7.0] - 2023-08-29

### Added

- Installation and usage instructions to the documentation. ([#159](https://github.com/JuliaTesting/Aqua.jl/pull/159))

### Changed

- `test_ambiguities` now allows to exclude non-singleton callables. Excluding a type means to exclude all methods of the callable (sometimes also called "functor") and the constructor. ([#144](https://github.com/JuliaTesting/Aqua.jl/pull/144)) [BREAKING]
- `test_piracy` considers more functions. Callables and qualified names are now also checked. ([#156](https://github.com/JuliaTesting/Aqua.jl/pull/156)) [BREAKING]

### Fixed

- `test_ambiguities` prints less unnecessary whitespace. ([#158](https://github.com/JuliaTesting/Aqua.jl/pull/158))
- `test_ambiguities` no longer hangs indefinitely when there are many ambiguities. ([#166](https://github.com/JuliaTesting/Aqua.jl/pull/166))


## [0.6.7] - 2023-09-19

### Changed

- `test_undefined_exports` additionally prints the modules of the undefined exports in the failure report. ([#177](https://github.com/JuliaTesting/Aqua.jl/pull/177))

### Fixed

- `test_ambiguities` prints less unnecessary whitespace. ([#158](https://github.com/JuliaTesting/Aqua.jl/pull/158))
- Fix `test_piracy` for some methods with arguments of custom subtypes of `Function`. ([#170](https://github.com/JuliaTesting/Aqua.jl/pull/170))


## [0.6.6] - 2023-08-24

### Fixed

- `test_ambiguities` no longer hangs indefinitely when there are many ambiguities. ([#166](https://github.com/JuliaTesting/Aqua.jl/pull/166))


## [0.6.5] - 2023-06-26

### Fixed

- Typo when calling kwargs. ([#153](https://github.com/JuliaTesting/Aqua.jl/pull/153))


## [0.6.4] - 2023-06-25

### Added

- `test_piracy` has a new kwarg `treat_as_own`. It is useful for testing packages that deliberately commit some type piracy, e.g. modules adding higher-level functionality to a lightweight C-wrapper, or packages that are extending `StatsAPI.jl`. ([#140](https://github.com/JuliaTesting/Aqua.jl/pull/140))

### Changed

- Explanation of `test_unbound_args` in the docstring. ([#146](https://github.com/JuliaTesting/Aqua.jl/pull/146))

### Fixed

- Callable objects with type parameters no longer error in `test_ambiguities`' kwarg `exclude`. ([#142](https://github.com/JuliaTesting/Aqua.jl/pull/142))


## [0.6.3] - 2023-06-05

### Changed

- When installing a method for a union type, it is only reported by `test_piracy` if *all* types in the union are foreign (instead of *any* for arguments). ([#131](https://github.com/JuliaTesting/Aqua.jl/pull/131))

### Fixed

- `test_deps_compat`'s kwarg `ignore` now works as intended. ([#130](https://github.com/JuliaTesting/Aqua.jl/pull/130))
- Weakdeps are not reported as stale by `test_stale_deps` anymore. ([#135](https://github.com/JuliaTesting/Aqua.jl/pull/135))


## [0.6.2] - 2023-06-02

### Added

- `test_ambiguities`, `test_undefined_exports`, `test_piracy`, and `test_unbound_args` each have a new kwarg `broken` to mark the test as broken using `Test.@test_broken`. ([#124](https://github.com/JuliaTesting/Aqua.jl/pull/124))

### Changed

- `test_piracy` now prints the offending methods in a more readable way. ([#93](https://github.com/JuliaTesting/Aqua.jl/pull/93))
- Extend `test_project_toml_formatting` to `docs/Project.toml`. ([#115](https://github.com/JuliaTesting/Aqua.jl/pull/115))

### Fixed

- `test_stale_deps` no longer fails if any of the loaded packages prints during loading. ([#113](https://github.com/JuliaTesting/Aqua.jl/pull/113))
- Clarified the error message of `test_unbound_args`. ([#103](https://github.com/JuliaTesting/Aqua.jl/pull/103))
- Clarified the error message of `test_project_toml_formatting`. ([#122](https://github.com/JuliaTesting/Aqua.jl/pull/122))
