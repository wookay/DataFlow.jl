using Flow, Flow.Fuzz
using Lazy, Base.Test

import Flow: equal, graphm, syntax

for nodes = 1:10, tries = 1:1_000

dl = grow(DVertex, nodes)

@test @> dl syntax(flatconst = false) graphm equal(dl)

end
