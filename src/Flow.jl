module Flow

using Lazy, MacroTools

export @flow, iscyclic

include("graph/graph.jl")
include("syntax.jl")

end # module
