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
        @test Aqua.has_persistent_tasks(getid("PersistentTask"); tmax = 2)

        result = Aqua.find_persistent_tasks_deps(getid("UsesBoth"); tmax = 2)
        @test result == ["PersistentTask"]
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
