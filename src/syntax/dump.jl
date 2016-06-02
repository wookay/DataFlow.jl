# Graph → Syntax

callmemaybe(f, a...) = isempty(a) ? f : :($f($(a...)))

tocall(f, a...) = callmemaybe(f, a...)

isconstant(v::Vertex) = isempty(inputs(v))

binding(bindings::Associative, v) = @get!(bindings, v, gensym("edge"))

function syntax(head::DVertex; flatconst = true)
  vs = topo(head)
  ex, bs = :(;), d()
  for v in vs
    x = tocall(value(v), [binding(bs, n) for n in inputs(v)]...)
    if flatconst && isconstant(v) && nout(v) > 1
      bs[v] = value(v)
    elseif nout(v) > 1 || (!isfinal(head) && v ≡ head)
      edge = binding(bs, v)
      push!(ex.args, :($edge = $x))
    elseif haskey(bs, v)
      if MacroTools.inexpr(ex, bs[v])
        ex = MacroTools.replace(ex, bs[v], x)
      else
        push!(ex.args, :($(bs[v]) = $x))
      end
    else
      isfinal(v) ? push!(ex.args, x) : (bs[v] = x)
    end
  end
  head ≢ vs[end] && push!(ex.args, binding(bs, head))
  return ex
end

# TODO: handle pre-constructor references

call2v(x) = x
call2v(ex::Expr) =
  isexpr(ex, :call) ?
    Expr(:call, :v, ex.args[1], map(x -> isexpr(x, :call) ? call2v(x) : :(v($x)), ex.args[2:end])...) :
    Expr(ex.head, map(call2v, ex.args)...)

function constructor(ex)
  ex = call2v(ex)
  ex′ = :(;)
  for x in block(ex).args
    @capture(x, v_ = v(f_, a__)) && inexpr(x.args[2], v) ?
      push!(ex′.args, :($v = v($f)), :(thread!($v, $(a...)))) :
      push!(ex′.args, x)
  end
  return ex′
end
