# Construction

type DVertex{T} <: Vertex{T}
  value::T
  inputs::Vector{DVertex{T}}
  outputs::OASet{DVertex{T}}

  DVertex(x) = new(x, [], OASet{DVertex{T}}())
end

DVertex(x) = DVertex{typeof(x)}(x)

value(v::DVertex) = v.value
inputs(v::DVertex) = v.inputs
outputs(v::DVertex) = v.outputs

function thread!(to::DVertex, from::DVertex)
  push!(inputs(to), from)
  push!(outputs(from), to)
  return to
end

v(a...) = DVertex{Any}(a...)

v(x::Vertex) = convert(DVertex{Any}, x)

dl(v::Vertex) = convert(DVertex, v)

function equal(a::Vertex, b::Vertex, seen = OSet())
  (a, b) ∈ seen && return true
  (value(a) == value(b) &&
    length(inputs(a)) == length(inputs(b)) &&
    length(outputs(a)) == length(outputs(b))) || return false
  push!(seen, (a, b))
  for (i, j) in zip(inputs(a), inputs(b))
    equal(i, j, seen) || return false
  end
  @assert @>> a outputs map(value) allunique
  @assert @>> b outputs map(value) allunique
  for o in outputs(a)
    p = filter(p -> value(p) == value(o), outputs(b))
    isempty(p) && return false
    equal(o, first(p), seen) || return false
  end
  return true
end
