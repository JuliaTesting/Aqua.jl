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
    filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
end

@testset "precompilation failure is reported" begin
    if Base.VERSION >= v"1.10-"
        # A package whose wrapper cannot precompile is not a persistent task, but the
        # probe can only report `true`. It must at least say why, rather than leaving
        # the caller to guess: the message names precompilation and carries the
        # captured output.
        msg = nothing
        logs = Test.collect_test_logs() do
            @test Aqua.has_persistent_tasks(getid("FailsToPrecompile"))
        end
        records = filter(r -> r.level == Base.CoreLogging.Error, logs[1])
        @test !isempty(records)
        if !isempty(records)
            msg = string(records[1].message)
            @test occursin("failed to precompile", msg)
            @test haskey(records[1].kwargs, :exitcode)
            @test haskey(records[1].kwargs, :precompilation)
            # `Pkg.precompile(; io)` writes its summary (and any "missing from the
            # cache" warnings) to `io`; the exception text itself goes to the worker's
            # stderr, which is already forwarded. The summary names what failed.
            @test occursin(
                "FailsToPrecompile",
                string(records[1].kwargs[:precompilation]),
            )
        end
        filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
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

end
