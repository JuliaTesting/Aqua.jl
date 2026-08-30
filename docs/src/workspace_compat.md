# Workspace compat entries

Since Julia 1.12, a package can declare its test project as a member of its
[workspace](https://pkgdocs.julialang.org/v1/toml-files/#The-[workspace]-section):

```toml
[workspace]
projects = ["test"]
```

Workspace members share a single manifest, and Pkg *intersects* the compat
bounds declared by every member when resolving it. A `[compat]` entry in
`test/Project.toml` for a name the root `Project.toml` already owns therefore
silently narrows the resolve: the root's declared bound stops being the
effective one, and nothing warns about it. Automated dependency update tools
can introduce exactly this failure mode when an update job is rooted at
`test/`, because they synthesize a compat entry for every direct dependency
that lacks one.

This test checks that, when the test project is a workspace member,
`test/Project.toml` does not declare a `[compat]` entry for any name the root
project already owns (its `deps`, its `weakdeps`, anything in its `[compat]`
including `julia`, or the package's own name). Bounds for genuinely test-only
dependencies are legitimate and are not flagged. For packages that do not
declare a test workspace, the test passes trivially.

## [Test function](@id test_workspace_compat)

```@docs
Aqua.test_workspace_compat
```
