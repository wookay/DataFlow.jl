function reaching(v::Vertex)
  # ...
end

isfinal(v::Vertex) = isempty(outputs(v))

Base.isless(a::Vertex, b::Vertex) = b in reaching(a)
