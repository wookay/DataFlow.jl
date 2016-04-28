import Base: copy, hash, ==

abstract AVertex{T}

Base.eltype{T}(::AVertex{T}) = T

immutable Needle{T}
  vertex::T
  output::Int
end

==(a::Needle, b::Needle) = a.output == b.output && a.vertex == b.vertex

include("set.jl")
include("dlgraph.jl")
include("ilgraph.jl")
include("conversions.jl")

thread!{T<:AVertex}(to::T, from::T) = thread!(to, Needle(from, 1))

thread!(to::AVertex, from) = thread!(to, typeof(to)(from))

thread!(v::AVertex, xs...) = reduce(thread!, v, xs)

(::Type{T}){T<:AVertex}(x, args...) = thread!(T(x), args...)

head(v::AVertex) = typeof(v)(value(v))

nout(v::AVertex) = length(outputs(v)) # FIXME
nin(v::AVertex) = length(inputs(v))

isfinal(v::AVertex) = nout(v) == 0
