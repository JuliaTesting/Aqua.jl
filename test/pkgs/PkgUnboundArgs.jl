module PkgUnboundArgs

# Putting it in a submodule to test that `recursive=true` is used.
module M25341
_totuple(::Type{Tuple{Vararg{E}}}, itr, s...) where {E} = E
end
# `_totuple` is taken from
# https://github.com/JuliaLang/julia/blob/48634f9f8669e1dc1be0a1589cd5be880c04055a/test/ambiguous.jl#L257-L259

end  # module
