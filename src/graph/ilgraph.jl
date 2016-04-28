type ILVertex{T} <: AVertex{T}
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

function walk(v::ILVertex, pre, post, cache = ODict())
  haskey(cache, v) && return cache[v]::typeof(v)
  v′ = pre(v)
  w = cache[v] = head(v′)
  for n in inputs(v′)
    thread!(w, typeof(n)(walk(n.vertex, pre, post, cache), n.output))
  end
  return post(w)
end

prewalk(f, v::ILVertex) = walk(v, f, identity)
postwalk(f, v::ILVertex) = walk(v, identity, f)

copy(v::ILVertex) = walk(v, identity, identity)

# TODO: check we don't get equivalent hashes for different graphs

function hash(v::ILVertex, h::UInt = UInt(0), seen = OSet())
  h = hash(value(v), h)
  v in seen ? (return h) : push!(seen, v)
  for n in inputs(v)
    h $= hash(n.vertex, hash(n.output), seen)
  end
  return h
end

==(a::ILVertex, b::ILVertex) = hash(a) == hash(b)
