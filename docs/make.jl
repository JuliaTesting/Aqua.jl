using Documenter, Aqua

makedocs(;
    modules=[Aqua],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        hide("internals.md"),
    ],
    repo="https://github.com/JuliaTesting/Aqua.jl/blob/{commit}{path}#L{line}",
    sitename="Aqua.jl",
    authors="Takafumi Arakaki",
)

deploydocs(;
    repo="github.com/JuliaTesting/Aqua.jl",
)
