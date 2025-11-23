"""
    test_undocumented_names(m::Module; broken::Bool = false)

Test that all public names in `m` and its recursive submodules have a docstring
(not including `m` itself).

!!! tip
    On all Julia versions, public names include the exported names.
    On Julia versions >= 1.11, public names also include the names annotated with the
    `public` keyword.

!!! warning
    When running this Aqua test in Julia versions before 1.11, it does nothing.
    Thus if you use continuous integration tests, make sure those are configured
    to use Julia >= 1.11 in order to benefit from this test.

# Keyword Arguments
- `broken`: If true, it uses `@test_broken` instead of
  `@test` and shortens the error message.
"""
function test_undocumented_names(m::Module; broken::Bool = false)
    @static if VERSION >= v"1.11"
        # exclude the module name itself because it has the README as auto-generated docstring (https://github.com/JuliaLang/julia/pull/39093)
        undocumented_names = Symbol[]
        walkmodules(m) do x
            append!(undocumented_names, Docs.undocumented_names(x))
        end
        undocumented_names = filter(n -> n != nameof(m), undocumented_names)
        if broken
            @test_broken isempty(undocumented_names)
        else
            @test isempty(undocumented_names)
        end
    else
        undocumented_names = Symbol[]
    end
    if !isempty(undocumented_names)
        printstyled(
            stderr,
            "Undocumented names detected:\n";
            bold = true,
            color = Base.error_color(),
        )
        !broken && show(stderr, MIME"text/plain"(), undocumented_names)
        println(stderr)
    end
end
