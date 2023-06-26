"""
    test_undefined_exports(module::Module)

Test that all `export`ed names in `module` actually exist.

# Keyword Arguments
- `broken::Bool = false`: If true, it uses `@test_broken` instead of
  `@test`.
"""
function test_undefined_exports(m::Module; broken::Bool = false)
    if broken
        @test_broken UndefinedExports.undefined_exports(m) == []
    else
        @test UndefinedExports.undefined_exports(m) == []
    end
end

module UndefinedExports

using ..Aqua: walkmodules

function undefined_exports(m::Module)
    undefined = Symbol[]
    walkmodules(m) do x
        for n in names(x)
            isdefined(x, n) || push!(undefined, n)
        end
    end
    return undefined
end

end # module
