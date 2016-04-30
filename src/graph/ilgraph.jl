type IVertex{T} <: Vertex{T}
  value::T
  inputs::Vector{IVertex{T}}

  IVertex(x) = new(x, [])
end

IVertex(x) = IVertex{typeof(x)}(x)

value(v::IVertex) = v.value
inputs(v::IVertex) = v.inputs
outputs(v::IVertex) = []
nout(v::IVertex) = 0

function thread!(to::IVertex, from::IVertex)
  push!(inputs(to), from)
  return to
end

il(v::Vertex) = convert(IVertex, v)

function walk(v::IVertex, pre, post, cache = ODict())
  haskey(cache, v) && return cache[v]::typeof(v)
  v′ = pre(v)
  w = cache[v] = head(v′)
  for n in inputs(v′)
    thread!(w, walk(n, pre, post, cache))
  end
  return post(w)
end

prewalk(f, v::IVertex) = walk(v, f, identity)
postwalk(f, v::IVertex) = walk(v, identity, f)

copy(v::IVertex) = walk(v, identity, identity)

# TODO: check we don't get equivalent hashes for different graphs

function hash(v::IVertex, h::UInt = UInt(0), seen = OSet())
  h = hash(value(v), h)
  v in seen ? (return h) : push!(seen, v)
  for n in inputs(v)
    h $= hash(n, h, seen)
  end
  return h
end

==(a::IVertex, b::IVertex) = hash(a) == hash(b)
