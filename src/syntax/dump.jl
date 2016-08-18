# Graph → Syntax

tocall(f, a...) = :($f($(a...)))

binding(bindings::Associative, v) =
  haskey(bindings, v) ? bindings[v] : (bindings[v] = gensym("edge"))

function syntax(head::DVertex; bindconst = !isfinal(head))
  vs = topo(head)
  ex, bs = :(;), ObjectIdDict()
  for v in vs
    x = tocall(value(v), [binding(bs, n) for n in inputs(v)]...)
    if !bindconst && isconstant(v) && nout(v) > 1
      bs[v] = value(v).value
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

function constructor(g)
  g = mapv(g) do v
    prethread!(v, typeof(v)(Constant(value(v))))
    v.value = :vertex
    v
  end
  ex = syntax(g)
  ex′ = :(;)
  for x in block(ex).args
    @capture(x, v_ = vertex(f_, a__)) && inexpr(x.args[2], v) ?
      push!(ex′.args, :($v = vertex($f)), :(thread!($v, $(a...)))) :
      push!(ex′.args, x)
  end
  return ex′
end
