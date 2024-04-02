using Documenter, Aqua, Changelog

# Generate a Documenter-friendly changelog from CHANGELOG.md
Changelog.generate(
    Changelog.Documenter(),
    joinpath(@__DIR__, "..", "CHANGELOG.md"),
    joinpath(@__DIR__, "src", "release-notes.md");
    repo = "JuliaTesting/Aqua.jl",
)

makedocs(;
    sitename = "Aqua.jl",
    format = Documenter.HTML(;
        repolink = "https://github.com/JuliaTesting/Aqua.jl",
        assets = ["assets/favicon.ico"],
        size_threshold_ignore = ["release-notes.md"],
    ),
    authors = "Takafumi Arakaki",
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
        "release-notes.md",
    ],
)

deploydocs(; repo = "github.com/JuliaTesting/Aqua.jl", push_preview = true)
