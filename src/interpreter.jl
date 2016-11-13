# TODO: stack and error messages

type Context{T}
  interp::T
  cache::ObjectIdDict
  data::Dict{Symbol,Any}
end

Context(interp; kws...) = Context(interp, ObjectIdDict(), Dict{Symbol,Any}(kws))

Base.getindex(ctx::Context, k::Symbol) = ctx.data[k]
Base.setindex!(ctx::Context, v, k::Symbol) = ctx.data[k] = v

function interpret(ctx::Context, graph::IVertex, args::IVertex...)
  graph = spliceinputs(graph, args...)
  interpret(ctx, graph)
end

interpret(ctx::Context, graph::IVertex, args...) =
  interpret(ctx, graph, map(constant, args)...)

function interpret(ctx::Context, graph::IVertex)
  haskey(ctx.cache, graph) && return ctx.cache[graph]
  ctx.cache[graph] = ctx.interp(ctx, value(graph), inputs(graph)...)
end

interpret(ctx::Context, xs::Tuple) = map(x -> interpret(ctx, x), xs)

# Composable interpreter pieces

function interpconst(f)
  interp(ctx::Context, x::Constant) = x.value
  interp(ctx::Context, xs...) = f(ctx, xs...)
end

function interptuple(f)
  interp(ctx::Context, ::Group, xs...) = tuple(interpret(ctx, xs)...)
  interp(ctx::Context, s::Split, xs) = interpret(ctx, xs)[s.n]
  interp(ctx::Context, xs...) = f(ctx, xs...)
end

interpnull(ctx, f, xs...) = vertex(f, interpret(ctx, xs)...)

const interpeval = interpconst(interptuple((ctx, f, xs...) -> f(interpret(ctx, xs)...)))

interpret(graph::IVertex, args...) =
  interpret(Context(interpeval), graph, args...)
