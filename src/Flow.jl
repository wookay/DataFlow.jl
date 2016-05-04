module Flow

using Lazy, MacroTools

include("graph/graph.jl")
include("syntax.jl")
include("operations.jl")
include("fuzz.jl")

end # module
