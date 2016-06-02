type Do end

tocall(::Do, a...) = :($(a...);)

type Assign{T}
  x::T
end

tocall(a::Assign, x) = :($(a.x) = $x)
