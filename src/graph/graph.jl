import Base: copy, hash, ==

abstract Vertex{T}

Base.eltype{T}(::Vertex{T}) = T

immutable Needle{T}
  vertex::T
  output::Int
end

==(a::Needle, b::Needle) = a.output == b.output && a.vertex == b.vertex

include("set.jl")
include("dlgraph.jl")
include("ilgraph.jl")
include("conversions.jl")

thread!{T<:Vertex}(to::T, from::T) = thread!(to, Needle(from, 1))

thread!(to::Vertex, from) = thread!(to, typeof(to)(from))

thread!(v::Vertex, xs...) = reduce(thread!, v, xs)

(::Type{T}){T<:Vertex}(x, args...) = thread!(T(x), args...)

head(v::Vertex) = typeof(v)(value(v))

nout(v::Vertex) = length(outputs(v)) # FIXME
nin(v::Vertex) = length(inputs(v))

isfinal(v::Vertex) = nout(v) == 0

neighbours(v::Vertex) =
  OSet{typeof(v)}(vcat(collect(outputs(v)), map(n->n.vertex, inputs(v))))

function collectv(v, s = OASet{typeof(v)}())
  v in s && return collect(s)
  push!(s, v)
  foreach(v -> collectv(v, s), neighbours(v))
  return collect(s)
end
