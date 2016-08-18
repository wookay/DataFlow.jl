immutable Constant{T}
  value::T
end

tocall(c::Constant) = c.value

isconstant(v::Vertex) = isa(value(v), Constant)

type Do end

tocall(::Do, a...) = :($(a...);)

type Assign{T}
  x::T
end

tocall(a::Assign, x) = :($(a.x) = $x)
