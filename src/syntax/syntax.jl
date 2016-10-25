import Base: @get!

include("read.jl")
include("dump.jl")
include("control.jl")

# Display

syntax(v::Vertex) = syntax(dl(v))

function Base.show(io::IO, v::Vertex)
  print(io, typeof(v))
  print(io, "(")
  s = MacroTools.alias_gensyms(syntax(v))
  if length(s.args) == 1
    print(io, sprint(print, s.args[1]))
  else
    foreach(x -> (println(io); print(io, sprint(print, x))), s.args)
  end
  print(io, ")")
end

import Juno: Row, Tree

code(x) = Juno.Model(Dict(:type=>"code",:text=>x))

@render Juno.Inline v::Vertex begin
  s = MacroTools.alias_gensyms(syntax(v))
  Tree(typeof(v), map(s -> code(string(s)), s.args))
end

# Function / expression macros

export @flow, @iflow, @dvertex, @ivertex

function inputsm(args)
  bindings = d()
  for arg in args
    isa(arg, Symbol) || error("invalid argument $arg")
    bindings[arg] = constant(arg)
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

function flowm(ex, f = dl)
  isdef(ex) && return flow_func(ex)
  g = graphm(block(ex))
  g = mapconst(x -> isexpr(x, :$) ? esc(x.args[1]) : Expr(:quote, x), g)
  constructor(f(g))
end

macro flow(ex)
  flowm(ex)
end

macro flow(ex)
  flowm(ex, il)
end

function vertexm(ex, f = dl)
  exs = graphm(block(ex))
  @>> exs graphm mapconst(esc) f constructor
end

macro dvertex(ex)
  vertexm(ex)
end

macro ivertex(ex)
  vertexm(ex, il)
end
