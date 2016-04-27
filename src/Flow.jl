module Flow

using Lazy, MacroTools

export @flow, iscyclic

include("graph/dlgraph.jl")
include("libdag.jl")
include("syntax.jl")

end # module
