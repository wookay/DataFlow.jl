immutable Constant{T}
  value::T
end

tocall(c::Constant) = c.value

isconstant(v::Vertex) = isa(value(v), Constant)

mapconst(f, g) = map(x -> isa(x, Constant) ? Constant(f(x.value)) : f(x), g)

constant(x) = vertex(Constant(x))
constant(v::Vertex) = vertex(v)

type Do end

tocall(::Do, a...) = :($(a...);)

type Assign{T}
  x::T
end

tocall(a::Assign, x) = :($(a.x) = $x)
