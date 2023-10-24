module PkgWithAmbiguities

# 1 ambiguity
f(::Any, ::Int) = 1
f(::Int, ::Any) = 2

abstract type AbstractType end
struct SingletonType <: AbstractType end

struct ConcreteType <: AbstractType
    x::Int
end

# 2 ambiguities
SingletonType(::Any, ::Any, ::Int) = 1
SingletonType(::Any, ::Int, ::Int) = 2
SingletonType(::Int, ::Any, ::Any) = 3

# 1 ambiguity
(::SingletonType)(::Any, ::Float64) = 1
(::SingletonType)(::Float64, ::Any) = 2

# 3 ambiguities
ConcreteType(::Any, ::Any, ::Int) = 1
ConcreteType(::Any, ::Int, ::Any) = 2
ConcreteType(::Int, ::Any, ::Any) = 3

# 1 ambiguity
(::ConcreteType)(::Any, ::Float64) = 1
(::ConcreteType)(::Float64, ::Any) = 2

# 1 ambiguitiy
abstract type AbstractParameterizedType{T} end
struct ConcreteParameterizedType{T} <: AbstractParameterizedType{T} end
(::AbstractParameterizedType{T})(::Tuple{Tuple{Int}}) where {T} = 1
(::ConcreteParameterizedType)(::Tuple) = 2

end  # module
