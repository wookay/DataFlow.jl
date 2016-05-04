# Flow

[![Build Status](https://travis-ci.org/MikeInnes/Flow.jl.svg?branch=master)](https://travis-ci.org/MikeInnes/Flow.jl) [![Coverage Status](https://coveralls.io/repos/github/MikeInnes/Flow.jl/badge.svg?branch=master)](https://coveralls.io/github/MikeInnes/Flow.jl?branch=master)

Flow.jl is an embedded language for expressing dataflow computations in Julia.

### Background

Modern applications that push computing power to churn through huge datasets, run vast simulations, or set up distributed deep learning across thousands of machines, often make use of a simplified dataflow programming model that is easier to analyse and optimise than imperative models.

However, these tools face a problem when providing interfaces from within a host language like Python or Java, since the dataflow model is at odds with their imperative semantics. What this means in practice is using the host language to create, compile and run expression trees for another, entirely independent, language. Most APIs pull some syntax hacks that make this somewhat convenient (for example, overloading functions so that calls like `exp(Constant(x))` construct an appropriate expression tree rather than being eagerly evaluated) but these interfaces still suffer convenience and composability issues.

Enter Julia. Julia has some powerful tools which enable us to embed dataflow semantics really seamlessly and naturally into the language, and Flow's aim is to do just that. Flow functions look and feel just like Julia functions, but they are stored under the hood as directed graphs which are interpreted at runtime. Flow functions can seamlessly call Julia functions and vice versa.

That in itself isn't all that exciting, but things get cool once you start writing plugins to Flow which can run specialised analysis / optimisation and even hand off to another runtime entirely. For example, one might run Flow programs on ComputeFramework.jl to distribute computations over a multi-gigabyte dataset, or TensorFlow for distributed machine learning. Likewise, one could extend the runtime to optimise away array allocations and support automatic differentiation for a Theano-like framework for machine learning. Even better, Flow will make it painless to extend these frameworks with numeric kernels written in Julia proper, rather than relying on unwieldy Cxx interop.

### Examples

#### Basics

Consider a definition like the following:

```julia
@flow function var(xs)
  mean = sum(xs)/length(xs)
  meansqr = sumabs2(xs)/length(xs)
  return meansqr - mean^2
end
```

This is perfectly valid Julia code, and will work as expected:

```julia
var([1,2,3]) => 0.666...
```

However, the `@flow` annotation on the function means that what's happening under the hood is very different. The program is actually stored as a directed graph which looks something like this:

![](static/variance.png)

In an imperative program we store intermediate results in variables and then reuse them at some later point. In data flow programs we avoid variables and model the flow of data through the program directly.

This has a number of advantages, but one immediate thing to notice is the obvious opportunity for parallelism revealed by the graph above –  the `mean` and `meansqr` calculations are manifestly independent and they can be executed at the same time without interfering, and once both are done we can calculate the result.

Currently, evaluating Flow functions directly just compiles them down to straightforward Julia code. You can see what code comes out:

```julia
Flow.toexpr(var.input) =>
  :(sum(xs .^ 2) / length(xs) - (sum(xs) / length(xs)) ^ 2)
```

(You'll notice that things are flattened out – Flow won't name intermediate values unless it needs to.)

#### Cycles

The example above basically shows off a subset of Julia's semantics, but it's important to remember that Flow can express *arbitrary* graphs, including those with cycles. For example:

```julia
@flow function recurrent(x)
  hidden = σ( Wxh*x + Whh*hidden )
  return σ( Why*hidden + Wxy*x )
end
```

This creates a program graph like the following:

![](static/recurrent.png)

Note the cycle going from `hidden` back to itself – this specifies a recurrent layer in a neural network, which contains hidden state.

You won't be able to call this function directly since there's no default way to handle cycles in the program – they just aren't meaningful on their own. However, plugins which extend Flow with time-delay nodes – responsible for propagating state forward through time steps and gradients backwards – will allow cyclic graphs like this to interpreted by a runtime.

Flow makes it easy to express program graphs of arbitrary complexity, so more complex recurrent architectures – LSTMs, hidden state threading through multiple layers etc. – are easy to express in a handful of lines as opposed to the hundreds required by Torch, for example. Of course, to actually be as usable as Torch we need a runtime capable of optimising memory usage, eliding allocations and running computations on the GPU, but that's a small matter of programming.

### Implementation details

Flow's programs are stored as directed multigraphs, that is, graphs in which any node can be connected to any other node multiple times. The basic graph data structure is the `DVertex`, defined as follows:

```julia
type DVertex{T}
  value::T
  inputs::Vector{Needle{DVertex{T}}}
  outputs::Set{DVertex{T}}
end
```

`value` is the data stored at that vertex (e.g. node label, function to call), `inputs` is a list of inputs from other nodes (e.g. arguments to the function) and `outputs` is a set of nodes which depend on the result of this one. "Functions" can have multiple outputs, so the `Needle` data type represents the idea of "output X of vertex Y".

This graph representation isn't so far from how regular expression trees are represented, and algorithms over the graph are written in a similar way; you write pretty much the same recursive style code but add a cache to avoid doing the same work twice (or indeed an infinite number of times). It may be instructive to see how `map`, which creates graphs of identical structure but new data, is implemented in `graph.jl`.
