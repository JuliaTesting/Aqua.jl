module PiracyForeignProject

struct ForeignType end
struct ForeignParameterizedType{T} end

struct ForeignNonSingletonType
    x::Int
end

# Type with a Symbol type parameter plus a type alias that fixes the Symbol.
# ForeignTaggedType tests that dispatching on the alias is detected as piracy
# (the :tag symbol is structural — it lives in this package's type alias),
# while dispatching on ForeignSymbolParamType{:user_symbol, T} directly is not
# (the :user_symbol could be a caller-defined dispatch tag).
struct ForeignSymbolParamType{S, T} end
const ForeignTaggedType{T} = ForeignSymbolParamType{:tag, T}

end
