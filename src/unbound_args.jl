"""
    test_unbound_args(m::Module; broken::Bool = false)

Test that all methods in `m` and its submodules do not have
unbound type parameters.

An unbound type parameter is a type parameter with a `where`, that does not
occur in the signature of some dispatch of the method.

# Keyword Arguments
- `broken`: If true, it uses `@test_broken` instead of
  `@test` and shortens the error message.
"""
function test_unbound_args(m::Module; broken::Bool = false)
    unbounds = detect_unbound_args_recursively(m)
    if broken
        if !isempty(unbounds)
            printstyled(
                stderr,
                "$(length(unbounds)) instances of unbound type parameters detected. To get a list, set `broken = false`.\n";
                bold = true,
                color = Base.error_color(),
            )
        end
        @test_broken isempty(unbounds)
    else
        if !isempty(unbounds)
            printstyled(
                stderr,
                "Unbound type parameters detected:\n";
                bold = true,
                color = Base.error_color(),
            )
            show(stderr, MIME"text/plain"(), unbounds)
            println(stderr)
        end

        @test isempty(unbounds)
    end
end

detect_unbound_args_recursively(m) = Test.detect_unbound_args(m; recursive = true)
