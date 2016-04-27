immutable ILVertex{T} <: AVertex{T}
  value::T
  inputs::Vector{Needle{ILVertex{T}}}

  ILVertex(x) = new(x, [])
end

ILVertex(x) = ILVertex{typeof(x)}(x)

value(v::ILVertex) = v.value
inputs(v::ILVertex) = v.inputs
Base.eltype{T}(::ILVertex{T}) = T

function thread!(to::ILVertex, from::Needle)
  push!(inputs(to), from)
  return to
end

il(v::AVertex) = convert(ILVertex, v)
