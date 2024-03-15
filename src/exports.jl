function walkmodules(f, x::Module)
    f(x)
    for n in names(x; all = true)
        # `isdefined` and `getproperty` can trigger deprecation warnings
        if Base.isbindingresolved(x, n) && !Base.isdeprecated(x, n)
            isdefined(x, n) || continue
            y = getproperty(x, n)
            if y isa Module && y !== x && parentmodule(y) === x
                walkmodules(f, y)
            end
        end
    end
end

function undefined_exports(m::Module)
    undefined = Symbol[]
    walkmodules(m) do x
        for n in names(x)
            isdefined(x, n) || push!(undefined, Symbol(join([fullname(x)...; n], '.')))
        end
    end
    return undefined
end

"""
    test_undefined_exports(module::Module)

Test that all `export`ed names in `module` actually exist.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test` and shortens the error message.
"""
function test_undefined_exports(m::Module; broken::Bool = false)
    exports = undefined_exports(m)
    if broken
        if !isempty(exports)
            printstyled(
                stderr,
                "$(length(exports)) undefined exports detected. To get a list, set `broken = false`.\n";
                bold = true,
                color = Base.error_color(),
            )
        end
        @test_broken isempty(exports)
    else
        if !isempty(exports)
            printstyled(
                stderr,
                "Undefined exports detected:\n";
                bold = true,
                color = Base.error_color(),
            )
            show(stderr, MIME"text/plain"(), exports)
            println(stderr)
        end
        @test isempty(exports)
    end
end
