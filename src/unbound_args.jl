"""
    test_unbound_args(module::Module)

Test that all methods in `module` and its submodules do not have
unbound type parameter.
"""
function test_unbound_args(m::Module; quiet::Bool = false)
    # https://github.com/JuliaLang/julia/pull/31972
    # @test detect_unbound_args(m; recursive=true) == []
    io = quiet ? devnull : stdout
    @test detect_unbound_args_recursively(io, m) == []
end

function detect_unbound_args_recursively(m)
    methods = []
    walkmodules(m) do x
        append!(methods, detect_unbound_args(x))
    end
    return methods
end

function detect_unbound_args_recursively(io::IO, m)
    methods = detect_unbound_args_recursively(m)
    print_unbound_args(io, methods)
    return methods
end

function print_unbound_args(io::IO, methods)
    buf = IOBuffer()
    for (i, mth) in enumerate(methods)
        println(io, "Unbound arg #", i)

        show(buf, mth)
        str = String(take!(buf))
        mtch = match(r"^(.*) at (.*\.jl:[0-9]+)", str)
        if mtch === nothing
            println(io, str)
        else
            println(io, mtch[1], " at:")
            printstyled(io, mtch[2]; bold = true)
            println(io)
        end
        println(io)
    end
end
