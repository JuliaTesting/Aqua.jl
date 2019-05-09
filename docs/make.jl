using Documenter, Aqua

makedocs(;
    modules=[Aqua],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/Aqua.jl/blob/{commit}{path}#L{line}",
    sitename="Aqua.jl",
    authors="Takafumi Arakaki",
)

deploydocs(;
    repo="github.com/tkf/Aqua.jl",
)
