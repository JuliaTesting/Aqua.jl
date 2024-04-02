using Documenter, Aqua

makedocs(;
    modules = [Aqua],
    pages = [
        "Home" => "index.md",
        "Tests" => [
            "test_all.md",
            "ambiguities.md",
            "unbound_args.md",
            "exports.md",
            "project_extras.md",
            "stale_deps.md",
            "deps_compat.md",
            "piracies.md",
            "persistent_tasks.md",
        ],
    ],
    sitename = "Aqua.jl",
    format = Documenter.HTML(;
        repolink = "https://github.com/JuliaTesting/Aqua.jl",
        assets = ["assets/favicon.ico"],
    ),
    authors =   "Takafumi Arakaki",
)

deploydocs( ; repo = "github.com/JuliaTesting/Aqua.jl", push_preview = true)
 