import Base: @get!

export @flow

# Syntax → Graph

type LateVertex{T}
  val::DVertex{T}
  args::Vector{Any}
end

function normedges(ex)
  ex = copy(ex)
  map!(ex.args) do ex
    @capture(ex, _ = _) ? ex : :($(gensym("edge")) = $ex)
  end
  return ex
end

function latenodes(exs)
  bindings = d()
  for ex in exs
    @capture(ex, b_Symbol = (f_(a__) | f_)) || error("invalid flow binding `$ex`")
    a = @or a []
    bindings[b] = LateVertex(v(f), a)
  end
  return bindings
end

graphm(bindings, node) = v(node)
graphm(bindings, node::Vertex) = node
graphm(bindings, ex::Symbol) =
  haskey(bindings, ex) ? graphm(bindings, bindings[ex]) : v(ex)
graphm(bindings, node::LateVertex) = node.val

function graphm(bindings, ex::Expr)
  isexpr(ex, :block) && return graphm(bindings, ex.args)
  @capture(ex, f_(args__)) || return v(ex)
  v(f, map(ex -> graphm(bindings, ex), args)...)
end

function fillnodes!(bindings)
  for (b, node) in bindings
    isa(node, LateVertex) && haskey(bindings, node.val.value) && (bindings[b] = bindings[node.val.value].val)
  end
  for (b, node) in bindings
    isa(node, LateVertex) || continue
    for arg in node.args
      thread!(node.val, graphm(bindings, arg))
    end
    bindings[b] = node.val
  end
  return bindings
end

function graphm(bindings, exs::Vector)
  exs = normedges(:($(exs...);)).args
  @capture(exs[end], result_Symbol = _)
  merge!(bindings, latenodes(exs))
  fillnodes!(bindings)
  output = graphm(bindings, result)
end

graphm(x) = graphm(d(), x)

# Graph → Syntax

callmemaybe(f, a...) = isempty(a) ? f : :($f($(a...)))

isconstant(v::DVertex) = isempty(inputs(v))

binding(bindings::Associative, v) = @get!(bindings, v, gensym("edge"))

function syntax(head::DVertex; flatconst = true)
  vs = topo(head)
  ex, bs = :(;), d()
  for v in vs
    x = callmemaybe(value(v), [binding(bs, n) for n in inputs(v)]...)
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

# function constructor(ex)
#   ex = MacroTools.prewalk(ex) do x
#     @capture(x, f_(a__)) ? :(vertex($f, $(a...))) : x
#   end
#   ex′ = :(;)
#   for x in block(ex).args
#     @capture(x, v_ = vertex(f_, a__)) && inexpr(x.args[2], v) ?
#       push!(ex′.args, :($v = vertex($f)), :(thread!($v, $(a...)))) :
#       push!(ex′.args, x)
#   end
#   return ex′
# end

# Display

syntax(v::Vertex) = syntax(dl(v))

function Base.show(io::IO, v::Vertex)
  println(io, typeof(v))
  s = MacroTools.alias_gensyms(syntax(v))
  print(io, join([sprint(print, x) for x in s.args], "\n"))
  # print(io, typeof(v), "(", value(v), ")")
end

# Function / expression macros

type Identity end

function inputsm(args)
  bindings = d()
  for arg in args
    isa(arg, Symbol) || error("invalid argument $arg")
    bindings[arg] = v(arg)
  end
  return bindings
end

type SyntaxGraph
  args::Vector{Symbol}
  output::DVertex{Any}
end

function flow_func(ex)
  @capture(shortdef(ex), name_(args__) = exs__)
  bs = inputsm(args)
  output = graphm(bs, exs)
  :($(esc(name)) = $(SyntaxGraph(args, output)))
end

macro flow(ex)
  isdef(ex) && return flow_func(ex)
  @capture(ex, exs__)
  graphm(exs)
end
