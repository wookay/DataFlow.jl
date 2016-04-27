# Construction

immutable Needle{T}
  vertex::T
  output::Int
end

type Vertex{T}
  value::T
  inputs::Vector{Needle{Vertex{T}}}
  outputs::Set{Vertex{T}}

  Vertex(x, args...) = thread!(new(x, [], Set{Vertex{T}}()), args...)
end

Vertex(x, args...) = Vertex{typeof(x)}(x, args...)

vertex(a...) = Vertex{Any}(a...)

value(v::Vertex) = v.value
inputs(v::Vertex) = v.inputs
outputs(v::Vertex) = v.outputs
Base.eltype{T}(::Vertex{T}) = T

function thread!(to::Vertex, from::Needle)
  push!(inputs(to), from)
  push!(outputs(from.vertex), to)
  return to
end

thread!(to::Vertex, from::Vertex) = thread!(to, Needle(from, 1))

thread!{T}(to::Vertex{T}, from) = thread!(to, Vertex{T}(from))

thread!(v::Vertex, xs...) = reduce(thread!, v, xs)

# Processing

function Base.map(f, v::Vertex; cache = d())
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

Base.copy(v::Vertex) = map(identity, v)

isfinal(v::Vertex) = isempty(outputs(v))
