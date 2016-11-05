import Base: ==

immutable Constant{T}
  value::T
end

tocall(c::Constant) = c.value

isconstant(v::Vertex) = isa(value(v), Constant)

mapconst(f, g) = map(x -> isa(x, Constant) ? Constant(f(x.value)) : f(x), g)

a::Constant == b::Constant = a.value == b.value

Base.hash(c::Constant, h::UInt = UInt(0)) = hash((Constant, c.value), h)

for (c, v) in [(:constant, :vertex), (:dconstant, :dvertex)]
  @eval $c(x) = $v(Constant(x))
  @eval $c(v::Vertex) = $v(v)
end

type Do end

tocall(::Do, a...) = :($(a...);)

immutable Group end

immutable Split
  n::Int
end

# TODO: printing
function normgroups(ex)
  MacroTools.prewalk(ex) do ex
    if @capture(ex, (xs__,) = y_)
      edge = gensym("edge")
      quote
        $edge = $y
        $((:($(xs[i]) = $(Split(i))($edge)) for i = 1:length(xs))...)
      end
    elseif @capture(ex, (xs__,))
      :($(Group())($(xs...)))
    else
      ex
    end
  end
end

tocall(::Group, args...) = :($(args...),)

tocall(s::Split, x) = :($x[$(s.n)])

group(xs...) = vertex(Group(), xs...)

# TODO: printing

immutable Bind
  name::Symbol
end

function insertbinds(ex)
  ls = map(ex.args) do l
    @capture(l, x_ = y_) || return l
    :($x = $(Bind(x))($y))
  end
  :($(ls...);)
end
