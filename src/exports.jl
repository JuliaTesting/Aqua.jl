function walkmodules(f, x::Module)
    f(x)
    for n in names(x)
        if isdefined(x, n)
            y = getproperty(x, n)
            if y isa Module && y !== x && parentmodule(y) === x
                walkmodules(f, y)
            end
        end
    end
end

"""
    undefined_exports(m::Module) :: Vector{Symbol}
"""
function undefined_exports(m::Module)
    undefined = Symbol[]
    walkmodules(m) do x
        for n in names(x)
            isdefined(x, n) || push!(undefined, n)
        end
    end
    return undefined
end
