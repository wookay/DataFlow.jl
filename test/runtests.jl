using Flow
using Base.Test

@flow function var(xs)
  mean = sum(xs)/length(xs)
  meansqr = sum(xs.^2)/length(xs)
  return meansqr - mean^2
end

@test_approx_eq var([1,2,3]) 2/3

@flow function recurrent(x)
  hidden = σ( Wxh*x + Whh*hidden )
  return σ( Why*hidden + Wxy*x )
end

@test iscyclic(recurrent.input)
