module Flow

using Lazy, MacroTools

export @flow, iscyclic

include("graph.jl")
include("syntax.jl")
include("expr.jl")

end # module
