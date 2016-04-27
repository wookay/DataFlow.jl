# Construction

type DLVertex{T} <: AVertex{T}
  value::T
  inputs::Vector{Needle{DLVertex{T}}}
  outputs::Set{DLVertex{T}}

  DLVertex(x) = new(x, [], Set{DLVertex{T}}())
end

DLVertex(x) = DLVertex{typeof(x)}(x)

value(v::DLVertex) = v.value
inputs(v::DLVertex) = v.inputs
outputs(v::DLVertex) = v.outputs
Base.eltype{T}(::DLVertex{T}) = T

function thread!(to::DLVertex, from::Needle)
  push!(inputs(to), from)
  push!(outputs(from.vertex), to)
  return to
end

vertex(a...) = DLVertex{Any}(a...)

dl(v::AVertex) = convert(DLVertex, v)

isfinal(v::DLVertex) = isempty(outputs(v))
