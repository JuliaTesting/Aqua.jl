using Documenter, Aqua

makedocs(;
    modules = [Aqua],
    pages = ["Home" => "index.md"],
    sitename = "Aqua.jl",
    format = Documenter.HTML(;
        repolink = "https://github.com/JuliaTesting/Aqua.jl",
        assets = ["assets/favicon.ico"],
    ),
    authors = "Takafumi Arakaki",
    warnonly = true,
)

deploydocs(; repo = "github.com/JuliaTesting/Aqua.jl", push_preview = true)
