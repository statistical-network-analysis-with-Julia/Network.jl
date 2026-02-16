# Types API Reference

This page documents the core data types in Network.jl.

## Abstract Types

### AbstractNetwork

```@docs
AbstractNetwork
```

## Network Types

### Network

```julia
mutable struct Network{T<:Integer} <: AbstractNetwork{T}
```

Core network data structure representing a network with optional vertex and edge attributes.

Mirrors R's `network` class from the statnet network package, while implementing Graphs.jl's `AbstractGraph` interface for interoperability with the Julia graph ecosystem.

**Type Parameters**

- `T`: Vertex ID type (typically `Int`)

**Fields**

| Field | Type | Description |
|-------|------|-------------|
| `graph` | `SimpleDiGraph{T}` | Underlying directed graph structure |
| `directed` | `Bool` | Whether edges are directed (affects interpretation, not storage) |
| `bipartite` | `Union{Nothing, Int}` | Number of vertices in first mode if bipartite, `nothing` otherwise |
| `loops` | `Bool` | Whether self-loops are allowed |
| `multiple` | `Bool` | Whether multiple edges between same vertices are allowed |
| `hyper` | `Bool` | Whether hyperedges are allowed |
| `vertex_attrs` | `Dict{Symbol, Dict{T, Any}}` | Vertex attributes by name |
| `edge_attrs` | `Dict{Symbol, Dict{Tuple{T,T}, Any}}` | Edge attributes by vertex pair |
| `network_attrs` | `Dict{Symbol, Any}` | Network-level attributes |

**Example**

```julia
# Create an empty directed network with 5 vertices
net = Network(5)

# Create an undirected network
net = Network(5; directed=false)

# Add edges
add_edge!(net, 1, 2)
add_edge!(net, 2, 3)

# Set vertex attributes
set_vertex_attribute!(net, :name, Dict(1 => "Alice", 2 => "Bob", 3 => "Carol"))

# Set edge attributes
set_edge_attribute!(net, :weight, Dict((1,2) => 1.5, (2,3) => 2.0))
```

### BipartiteNetwork

```@docs
BipartiteNetwork
```

## Constructors

### network

```@docs
network
```

### network\_initialize

```@docs
network_initialize
```
