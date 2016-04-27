abstract AVertex{T}

immutable Needle{T}
  vertex::T
  output::Int
end

include("dlgraph.jl")
include("ilgraph.jl")

thread!{T<:AVertex}(to::T, from::T) = thread!(to, Needle(from, 1))

thread!(to::AVertex, from) = thread!(to, typeof(to)(from))

thread!(v::AVertex, xs...) = reduce(thread!, v, xs)

(::Type{T}){T<:AVertex}(x, args...) = thread!(T(x), args...)
