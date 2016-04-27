Base.convert{T}(::Type{Needle{T}}, n::Needle) =
  Needle{T}(convert(T, n.vertex), n.output)

for (V, W) in [(DLVertex, ILVertex), (ILVertex, DLVertex)]
  @eval function Base.convert{W<:$W}(::Type{W}, v::$V, cache = d())
    haskey(cache, v) && return cache[v]
    w = cache[v] = W(value(v))
    thread!(w, [Needle{W}(convert(W, n.vertex, cache), n.output) for n in inputs(v)]...)
  end
end
