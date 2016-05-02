import Base: copy, hash, ==, <, <<

abstract Vertex{T}

Base.eltype{T}(::Vertex{T}) = T

include("set.jl")
include("dlgraph.jl")
include("ilgraph.jl")
include("conversions.jl")

thread!(to::Vertex, from) = thread!(to, typeof(to)(from))

thread!(v::Vertex, xs...) = reduce(thread!, v, xs)

(::Type{T}){T<:Vertex}(x, args...) = thread!(T(x), args...)

head(v::Vertex) = typeof(v)(value(v))

nin(v::Vertex) = length(inputs(v))

function nout(v::Vertex)
  n = 0
  for o in outputs(v), i in inputs(o)
    i ≡ v && (n += 1)
  end
  return n
end

isfinal(v::Vertex) = nout(v) == 0

function collectv(v::Vertex, vs = OASet{eltype(v)}())
  v ∈ vs && return collect(vs)
  push!(vs, v)
  foreach(v′ -> collectv(v′, vs), inputs(v))
  foreach(v′ -> collectv(v′, vs), outputs(v))
  return collect(vs)
end

function isreaching(from::Vertex, to::Vertex, seen = OSet())
  to ∈ seen && return false
  push!(seen, to)
  any(v -> v ≡ from || isreaching(from, v, seen), inputs(to))
end

Base.isless(a::Vertex, b::Vertex) = isreaching(a, b)

<<(a::Vertex, b::Vertex) = a < b && !(a > b)

toposort!(vs) = sort!(vs, lt = (x, y) -> !(y << x), alg = MergeSort)

function istopo(vs)
  for i = 1:length(vs)
    for j = 1:i-1
      !(vs[i] << vs[j]) || return false
    end
    for j = i+1:length(vs)
      !(vs[j] << vs[i]) || return false
    end
  end
  return true
end

↺(v::Vertex) = v < v
↺(a::Vertex, b::Vertex) = a < b && b < a
