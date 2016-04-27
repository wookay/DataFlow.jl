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

function copy(v::ILVertex, cache = ODict())
  haskey(cache, v) && return cache[v]
  w = cache[v] = typeof(v)(value(v))
  for n in inputs(v)
    thread!(w, typeof(n)(copy(n.vertex, cache), n.output))
  end
  return w
end

function hash(v::ILVertex, h::UInt = UInt(0), seen = OSet())
  h = hash(value(v), h)
  v in seen ? (return h) : push!(seen, v)
  for n in inputs(v)
    h $= hash(n.vertex, hash(n.output), seen)
  end
  return h
end

==(a::ILVertex, b::ILVertex) = hash(a) == hash(b)
