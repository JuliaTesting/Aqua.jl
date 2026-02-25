"""
    test_explicit_imports(m::Module; kwargs...)

Run the various tests provided by the package [ExplicitImports.jl](https://github.com/ericphanson/ExplicitImports.jl).

# Keyword Arguments

Same as those of the function [`ExplicitImports.test_explicit_imports`](@extref). 
"""
function test_explicit_imports(m::Module; kwargs...)
    # TODO: explicitly list kwargs here?
    ExplicitImports.test_explicit_imports(m; kwargs...)
end
