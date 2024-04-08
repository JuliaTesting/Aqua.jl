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
        @test Aqua.has_persistent_tasks(getid("PersistentTask"))

        result = Aqua.find_persistent_tasks_deps(getid("UsesBoth"))
        @test result == ["PersistentTask"]
    end
end

@testset "test_persistent_tasks(expr)" begin
    if Base.VERSION >= v"1.10-"
        @test !Aqua.has_persistent_tasks(
            getid("TransientTask"),
            expr = quote
                fetch(Threads.@spawn nothing)
            end,
        )
        @test Aqua.has_persistent_tasks(getid("TransientTask"), expr = quote
            Threads.@spawn while true
                sleep(0.5)
            end
        end)
    end
end

@testset "test_persistent_tasks(expr)" begin
    if Base.VERSION >= v"1.10-"
        @test !Aqua.has_persistent_tasks(
            getid("TransientTask"),
            expr = quote
                fetch(Threads.@spawn nothing)
            end,
        )
        @test Aqua.has_persistent_tasks(getid("TransientTask"), expr = quote
            Threads.@spawn while true
                sleep(0.5)
            end
        end)
    end
end

@testset "test_persistent_tasks with precompilable error" begin
    if Base.VERSION >= v"1.10-"
        println("### Expected output START ###")
        @test !Aqua.has_persistent_tasks(
            getid("PrecompilableErrorPkg");
            succeed_on_precompilable_error = true,
        )
        @test Aqua.has_persistent_tasks(
            getid("PrecompilableErrorPkg");
            succeed_on_precompilable_error = false,
        )
        println("### Expected output END ###")
    end
end

end
