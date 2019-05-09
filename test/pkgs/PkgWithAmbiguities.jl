module PkgWithAmbiguities

f(::Any, ::Int) = 1
f(::Int, ::Any) = 2

end  # module
