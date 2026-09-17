module TestPersistentTasks

include("preamble.jl")
using Base: PkgId, UUID
using Pkg: TOML

function getid(name)
    path = joinpath(@__DIR__, "pkgs", "PersistentTasks", name)
    if path ∉ LOAD_PATH
        pushfirst!(LOAD_PATH, path)
    end
    prj = TOML.parsefile(joinpath(path, "Project.toml"))
    return PkgId(UUID(prj["uuid"]), prj["name"])
end


@testset "PersistentTasks" begin
    @test !Aqua.has_persistent_tasks(getid("TransientTask"))

    result = Aqua.find_persistent_tasks_deps(getid("TransientTask"))
    @test result == []

    if Base.VERSION >= v"1.10-"
        println("### Expected output START ###")
        @test Aqua.has_persistent_tasks(getid("PersistentTask"); tmax = 2)

        result = Aqua.find_persistent_tasks_deps(getid("UsesBoth"); tmax = 2)
        println("### Expected output END ###")
        @test result == ["PersistentTask"]

        # `UsesTransientTask` depends on the unregistered `TransientTask`, which is
        # only reachable through the stacked `LOAD_PATH`; the check must respect
        # this environment.
        @test !Aqua.has_persistent_tasks(getid("UsesTransientTask"))
    end
    filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
end

@testset "dependencies tracked by path in the manifest" begin
    if Base.VERSION >= v"1.10-"
        # `WithDevDep` depends on the unregistered `TransientTask`, which is only
        # reachable through the relative `path` entry in `WithDevDep/Manifest.toml`
        # (like a `dev`ed dependency). Only `WithDevDep` itself is put on the
        # `LOAD_PATH`.
        @test !Aqua.has_persistent_tasks(getid("WithDevDep"))
    end
    filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
end

@testset "weak dependency duplicated in [deps]" begin
    # `WithWeakDep` lists `WeakDep` in both `[deps]` and `[weakdeps]`, the idiom
    # for supporting Julia < 1.9. Issue #399.
    getid("TransientTask")
    id = getid("WithWeakDep")
    pkgdir = joinpath(@__DIR__, "pkgs", "PersistentTasks", "WithWeakDep")

    # `WeakDep` is not installed: it must be skipped, not errored on, and the
    # manifest must not claim it as a dependency.
    entries = Aqua.manifest_entries(pkgdir)
    @test !haskey(entries, "WeakDep")
    entry = Aqua.only(entries["WithWeakDep"])
    @test !haskey(entry["deps"], "WeakDep")
    @test haskey(entry["weakdeps"], "WeakDep")
    if Base.VERSION >= v"1.10-"
        @test !Aqua.has_persistent_tasks(id)
    end

    # Once installed, the weak dependency is traversed so the extension stays
    # loadable, but it still is not one of the entry's `deps`.
    getid("WeakDep")
    entries = Aqua.manifest_entries(pkgdir)
    @test haskey(entries, "WeakDep")
    @test !haskey(Aqua.only(entries["WithWeakDep"])["deps"], "WeakDep")
    if Base.VERSION >= v"1.10-"
        @test !Aqua.has_persistent_tasks(id)
    end
    filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
end

@testset "precompilation failure is reported as an error" begin
    if Base.VERSION >= v"1.10-"
        # A package that fails to precompile must be reported as a
        # precompilation error rather than misclassified as a persistent task.
        @test_throws "precompilation error" Aqua.has_persistent_tasks(
            getid("FailsToPrecompile"),
        )
    end
    filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
end

@testset "test_persistent_tasks(expr)" begin
    if Base.VERSION >= v"1.10-"
        @test !Aqua.has_persistent_tasks(
            getid("TransientTask"),
            expr = quote
                fetch(Threads.@spawn nothing)
            end,
        )
        @test Aqua.has_persistent_tasks(
            getid("TransientTask"),
            tmax = 2,
            expr = quote
                Threads.@spawn while true
                    sleep(0.5)
                end
            end,
        )
    end
end

end
