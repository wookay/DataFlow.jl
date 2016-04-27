import Base: convert

convert{T}(::Type{Needle{T}}, n::Needle) =
  Needle{T}(convert(T, n.vertex), n.output)

for (V, W) in [(DLVertex, ILVertex), (ILVertex, DLVertex)]
  @eval function convert{T}(::Type{$W{T}}, v::$V, cache = d())
    haskey(cache, v) && return cache[v]
    w = cache[v] = $W{T}(value(v))
    thread!(w, [Needle{$W{T}}(convert($W{T}, n.vertex, cache), n.output) for n in inputs(v)]...)
  end
  @eval convert(::Type{$W}, v::AVertex) = convert($W{eltype(v)}, v)
end
