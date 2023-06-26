module PkgWithAmbiguities

f(::Any, ::Int) = 1
f(::Int, ::Any) = 2

@static if VERSION >= v"1.3-"
    abstract type AbstractType{T} end
    struct ConcreteType{T} <: AbstractType{T} end
    (::AbstractType{T})(::Tuple{Tuple{Int}}) where {T} = 1
    (::ConcreteType)(::Tuple) = 2
end

end  # module
