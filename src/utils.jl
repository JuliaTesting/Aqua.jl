struct LazyTestResult
    label::String
    message::String
    pass::Bool
end

ispass(result::LazyTestResult) = result.pass

# Infix operator wrapping `ispass` so that the failure case is pretty-printed
⊜(result, yes::Bool) = ispass(result)::Bool == yes

# To be shown via `@test` when failed:
function Base.show(io::IO, result::LazyTestResult)
    print(io, "⟪result: ")
    show(io, MIME"text/plain"(), result)
    print(io, "⟫")
end

function Base.show(io::IO, ::MIME"text/plain", result::LazyTestResult)
    if ispass(result)
        printstyled(io, "✔ PASS"; color = :green, bold = true)
    else
        printstyled(io, "😭 FAILED"; color = :red, bold = true)
    end
    println(io, ": ", result.label)
    for line in eachline(IOBuffer(result.message))
        println(io, " "^4, line)
    end
end
