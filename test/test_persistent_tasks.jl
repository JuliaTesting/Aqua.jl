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
    Aqua.test_persistent_tasks(getid("TransientTask"))
    Aqua.test_persistent_tasks_deps(getid("TransientTask"))

    if all((Base.VERSION.major, Base.VERSION.minor) .>= (1, 10))
        Aqua.test_persistent_tasks(getid("PersistentTask"); fails=true)
        Aqua.test_persistent_tasks_deps(getid("UsesBoth"); fails=Dict("PersistentTask" => true))
    end
    filter!(str -> !occursin("PersistentTasks", str), LOAD_PATH)
end

end
