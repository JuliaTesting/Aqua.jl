"""
    test_undocumented_names(module::Module)

Test that all public names in `module` have a docstring (not including the module itself).

!!! tip
    On all Julia versions, public names include the exported names.
    On Julia versions >= 1.11, public names also include the names annotated with the `public` keyword.

!!! warning
    When running this Aqua test in Julia versions before 1.11, it does nothing.
    Thus if you use continuous integration tests, make sure those are configured
    to use Julia >= 1.11 in order to benefit from this test.
"""
function test_undocumented_names(m::Module)
    @static if VERSION >= v"1.11"
        # exclude the module name itself because it has the README as auto-generated docstring (https://github.com/JuliaLang/julia/pull/39093)
        undocumented_names = filter(n -> n != nameof(m), Docs.undocumented_names(m))
        @test isempty(undocumented_names)
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
        show(stderr, MIME"text/plain"(), undocumented_names)
        println(stderr)
    end
end
