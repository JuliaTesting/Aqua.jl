"""
    test_undocumented_names(module::Module)

Test that all public names in `module` have a docstring (including the module itself).

!!! warning
    For Julia versions before 1.11, this does not test anything.
"""
function test_undocumented_names(m::Module)
    @static if VERSION >= v"1.11"
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
