module PkgWithAmbiguities

# 1 ambiguity
f(::Any, ::Int) = 1
f(::Int, ::Any) = 2
const num_ambs_f = 1

# 2 ambiguities:
#   1 for g
#   1 for Core.kwfunc(g) if VERSION >= 1.4
#   2 for Core.kwfunc(g) if VERSION < 1.4
g(::Any, ::Int; kw) = 1
g(::Int, ::Any; kw) = 2
const num_ambs_g = VERSION >= v"1.4-" ? 2 : 3

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

const num_ambs_SingletonType = 3

# 3 ambiguities
ConcreteType(::Any, ::Any, ::Int) = 1
ConcreteType(::Any, ::Int, ::Any) = 2
ConcreteType(::Int, ::Any, ::Any) = 3

# 1 ambiguity
(::ConcreteType)(::Any, ::Float64) = 1
(::ConcreteType)(::Float64, ::Any) = 2

const num_ambs_ConcreteType = 4

@static if VERSION >= v"1.3-"
    # 1 ambiguity if VERSION >= 1.3
    abstract type AbstractParameterizedType{T} end
    struct ConcreteParameterizedType{T} <: AbstractParameterizedType{T} end
    (::AbstractParameterizedType{T})(::Tuple{Tuple{Int}}) where {T} = 1
    (::ConcreteParameterizedType)(::Tuple) = 2
end

const num_ambs_ParameterizedType = 1

end  # module
