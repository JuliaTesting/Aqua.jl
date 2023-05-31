using Documenter, Aqua

makedocs(;
    modules = [Aqua],
    pages = ["Home" => "index.md", hide("internals.md")],
    sitename = "Aqua.jl",
    authors = "Takafumi Arakaki",
)

deploydocs(; repo = "github.com/JuliaTesting/Aqua.jl", push_preview = true)
