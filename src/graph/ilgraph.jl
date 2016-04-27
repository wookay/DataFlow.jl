immutable ILVertex{T} <: AVertex{T}
  value::T
  inputs::Vector{Needle{ILVertex{T}}}

  ILVertex(x) = new(x, [])
end

ILVertex(x) = ILVertex{typeof(x)}(x)

value(v::ILVertex) = v.value
inputs(v::ILVertex) = v.inputs

function thread!(to::ILVertex, from::Needle)
  push!(inputs(to), from)
  return to
end

il(v::AVertex) = convert(ILVertex, v)

# TODO: figure out how to factor out the caching pattern

function Base.copy(v::ILVertex, cache = Dict{eltype(v),eltype(v)}())
  haskey(cache, v) && return cache[v]
  w = cache[v] = typeof(v)(value(v))
  for n in inputs(v)
    thread!(w, typeof(n)(copy(n.vertex, cache), n.output))
  end
  return w
end
