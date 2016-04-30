# Construction

type DVertex{T} <: Vertex{T}
  value::T
  inputs::Vector{DVertex{T}}
  outputs::OSet{DVertex{T}}

  DVertex(x) = new(x, [], OSet{DVertex{T}}())
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

vertex(a...) = DVertex{Any}(a...)

dl(v::Vertex) = convert(DVertex, v)
