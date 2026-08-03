module TestPersistentTasks

include("preamble.jl")
using Base: PkgId, UUID
import Pkg
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
    if Base.VERSION >= v"1.10-"
        respect_sysimage_versions = Pkg.RESPECT_SYSIMAGE_VERSIONS[]
        Pkg.respect_sysimage_versions(false)
        try
            @test !Aqua.has_persistent_tasks(getid("TransientTask"))
            @test !Pkg.RESPECT_SYSIMAGE_VERSIONS[]
        finally
            Pkg.respect_sysimage_versions(respect_sysimage_versions)
        end
    else
        @test !Aqua.has_persistent_tasks(getid("TransientTask"))
    end

    result = Aqua.find_persistent_tasks_deps(getid("TransientTask"))
    @test result == []

    if Base.VERSION >= v"1.10-"
        println("### Expected output START ###")
        @test Aqua.has_persistent_tasks(getid("PersistentTask"); tmax = 2)

        result = Aqua.find_persistent_tasks_deps(getid("UsesBoth"); tmax = 2)
        println("### Expected output END ###")
        @test result == ["PersistentTask"]
    end
    filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
end

@testset "subprocess exit handling" begin
    if Base.VERSION >= v"1.10-"
        statusfile = tempname()
        errlog = tempname()
        write(errlog, "failure after loading")
        proc = run(`$(Base.julia_cmd()) --startup-file=no -e 'exit(7)'`; wait = false)
        touch(statusfile)
        handle = (; proc, statusfile, errlog, pkgname = "FailedAfterLoading")
        @test_throws "process exited with code 7" Aqua.await_precompile_wrapper(handle, 1)

        proc = run(`$(Base.julia_cmd()) --startup-file=no -e 'sleep(60)'`; wait = false)
        handle = (; proc, statusfile, errlog, pkgname = "Stopped")
        Aqua.stop_precompile_wrapper(handle)
        @test !process_running(proc)
    end
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
