using Flow, Flow.Fuzz
using MacroTools, Lazy, Base.Test

import Flow: equal, graphm, syntax, cse

for nodes = 1:10, tries = 1:1_000

dl = grow(DVertex, nodes)

@test @> dl syntax(flatconst = false) graphm equal(dl)

il = grow(IVertex, nodes)

@test @> il Flow.dl() Flow.il() equal(il)

@test copy(il) == il == prewalk(identity, il)

end

@flow function recurrent(xs)
  hidden = σ( Wxh*xs + Whh*hidden + bh )
  σ( Wxy*x + Why*hidden + by )
end

@test @capture syntax(recurrent.output) begin
  h_Symbol = σ( Wxh*xs + Whh*h_Symbol + bh )
  σ( Wxy*x + Why*h_Symbol + by )
end

@flow function var(xs)
  mean = sum(xs)/length(xs)
  meansqr = sumabs2(xs)/length(xs)
  meansqr - mean^2
end

@test @capture syntax(var.output) begin
  sumabs2(xs)/length(xs) - (sum(xs) / length(xs)) ^ 2
end

@test contains(sprint(show, var),
               string(:(sumabs2(xs)/length(xs) - (sum(xs) / length(xs)) ^ 2)))

@test @capture syntax(cse(var.output)) begin
  n_Symbol = length(xs)
  sumabs2(xs)/n_Symbol - (sum(xs) / n_Symbol) ^ 2
end
