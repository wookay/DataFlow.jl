import Base: ==

immutable Constant{T}
  value::T
end

tocall(c::Constant) = c.value

isconstant(v::Vertex) = isa(value(v), Constant)

mapconst(f, g) = map(x -> isa(x, Constant) ? Constant(f(x.value)) : f(x), g)

a::Constant == b::Constant = a.value == b.value

Base.hash(c::Constant, h::UInt = UInt(0)) = hash((Constant, c.value), h)

for (c, v) in [(:constant, :vertex), (:dconstant, dvertex)]
  @eval $c(x) = $v(Constant(x))
  @eval $c(v::Vertex) = $v(v)
end

type Do end

tocall(::Do, a...) = :($(a...);)
