typealias ODict ObjectIdDict

immutable ObjectIdSet{T}
  dict::ObjectIdDict
  ObjectIdSet() = new(ObjectIdDict())
end

Base.eltype{T}(::ObjectIdSet{T}) = T

ObjectIdSet() = ObjectIdSet{Any}()

Base.push!{T}(s::ObjectIdSet, x::T) = (s.dict[x] = nothing; s)
Base.in(x, s::ObjectIdSet) = haskey(s.dict, x)

ObjectIdSet(xs) = push!(ObjectIdSet{eltype(xs)}(), xs...)

typealias OSet ObjectIdSet

immutable ObjectArraySet{T}
  xs::Vector{T}
  ObjectArraySet() = new(T[])
end

Base.in{T}(x::T, s::ObjectArraySet{T}) = any(y -> x ≡ y, s.xs)
Base.push!(s::ObjectArraySet, x) = (x ∉ s && push!(s.xs, x); s)

ObjectArraySet(xs) = push!(ObjectArraySet{eltype(xs)}(), xs...)

@forward ObjectArraySet.xs Base.length

typealias OASet{T} ObjectArraySet{T}
