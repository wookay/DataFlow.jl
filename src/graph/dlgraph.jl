# Construction

immutable Needle{T}
  vertex::T
  output::Int
end

type DLVertex{T}
  value::T
  inputs::Vector{Needle{DLVertex{T}}}
  outputs::Set{DLVertex{T}}

  DLVertex(x, args...) = thread!(new(x, [], Set{DLVertex{T}}()), args...)
end

DLVertex(x, args...) = DLVertex{typeof(x)}(x, args...)

vertex(a...) = DLVertex{Any}(a...)

value(v::DLVertex) = v.value
inputs(v::DLVertex) = v.inputs
outputs(v::DLVertex) = v.outputs
Base.eltype{T}(::DLVertex{T}) = T

function thread!(to::DLVertex, from::Needle)
  push!(inputs(to), from)
  push!(outputs(from.vertex), to)
  return to
end

thread!(to::DLVertex, from::DLVertex) = thread!(to, Needle(from, 1))

thread!{T}(to::DLVertex{T}, from) = thread!(to, DLVertex{T}(from))

thread!(v::DLVertex, xs...) = reduce(thread!, v, xs)

# Processing

function Base.map(f, v::DLVertex; cache = d())
  haskey(cache, v) && return cache[v]
  node = vertex(f(value(v)))
  cache[v] = node
  for out in outputs(v)
    push!(node.outputs, map(f, out, cache = cache))
  end
  for in in inputs(v)
    push!(node.inputs, Needle(map(f, in.vertex, cache = cache), in.output))
  end
  return node
end

Base.copy(v::DLVertex) = map(identity, v)

isfinal(v::DLVertex) = isempty(outputs(v))
