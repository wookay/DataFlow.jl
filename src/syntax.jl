# Syntax → Graph

type LateVertex{T}
  val::DVertex{T}
  args::Vector{Any}
end

function latenodes(exs)
  bindings = d()
  for ex in exs
    @capture(ex, b_Symbol = f_(a__)) || error("invalid flow binding `$ex`")
    bindings[b] = LateVertex(vertex(f), a)
  end
  return bindings
end

graphm(bindings, node) = node
graphm(bindings, ex::Symbol) =
  haskey(bindings, ex) ? graphm(bindings, bindings[ex]) : ex
graphm(bindings, node::LateVertex) = node.val

function graphm(bindings, ex::Expr)
  @capture(ex, f_(args__)) || error("invalid flow expression `$ex`")
  vertex(f, map(ex -> graphm(bindings, ex), args)...)
end

function extractresult!(args)
  @match args[end] begin
    (return a_) => (args[end] = a; extractresult!(args))
    (out_ = _) => out
    _ => pop!(args)
  end
end

function fillnodes!(bindings)
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
  result = extractresult!(exs)
  merge!(bindings, latenodes(exs))
  fillnodes!(bindings)
  output = graphm(bindings, result)
end

graphm(x) = graphm(d(), x)

# Graph → Syntax
# TODO: islands, multiple outputs

callmemaybe(f, a...) = isempty(a) ? f : :($f($(a...)))

isconstant(v::DVertex) = isa(value(v), Symbol) && isempty(inputs(v))

function syntax!(v::DVertex, ex, bindings = d())
  haskey(bindings, v) && return bindings[v]
  x = () -> callmemaybe(value(v), [syntax!(v, ex, bindings) for v in inputs(v)]...)
  if nout(v) > 1
    isconstant(v) && return (bindings[v] = value(v))
    @gensym edge
    bindings[v] = edge
    push!(ex.args, :($edge = $(x())))
    return edge
  else
    x′ = x()
    isfinal(v) && push!(ex.args, x′)
    return x′
  end
end

syntax!(n::Needle, ex, bindings = d()) =
  syntax!(n.vertex, ex, bindings) # FIXME

function syntax(v::DVertex)
  ex = :(;)
  syntax!(v, ex)
  ex
end

function constructor(ex)
  ex = MacroTools.prewalk(ex) do x
    @capture(x, f_(a__)) ? :(vertex($f, $(a...))) : x
  end
  ex′ = :(;)
  for x in block(ex).args
    @capture(x, v_ = vertex(f_, a__)) && inexpr(x.args[2], v) ?
      push!(ex′.args, :($v = vertex($f)), :(thread!($v, $(a...)))) :
      push!(ex′.args, x)
  end
  return ex′
end

# Display

syntax(v::AVertex) = syntax(dl(v))

function Base.show(io::IO, v::AVertex)
  println(io, typeof(v))
  s = MacroTools.alias_gensyms(syntax(v))
  print(io, join([sprint(print, x) for x in s.args], "\n"))
end

# Function / expression macros

type Identity end

function inputsm(args)
  bindings = d()
  for arg in args
    isa(arg, Symbol) || error("invalid argument $arg")
    bindings[arg] = vertex(arg)
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
