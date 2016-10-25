module Flow

using Lazy, MacroTools, Juno

include("graph/graph.jl")
include("syntax/syntax.jl")
include("operations.jl")
include("fuzz.jl")

end # module
