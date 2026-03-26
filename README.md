# Network.jl


[![Network Analysis](https://img.shields.io/badge/Network-Analysis-orange.svg)](https://github.com/statistical-network-analysis-with-Julia/Network.jl)
[![Build Status](https://github.com/statistical-network-analysis-with-Julia/Network.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/statistical-network-analysis-with-Julia/Network.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://statistical-network-analysis-with-Julia.github.io/Network.jl/stable/)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://statistical-network-analysis-with-Julia.github.io/Network.jl/dev/)
[![Julia](https://img.shields.io/badge/Julia-1.9+-purple.svg)](https://julialang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <img src="docs/src/assets/logo.svg" alt="Network.jl icon" width="160">
</p>

Core network data structures for the StatNet Julia ecosystem.

## Overview

Network.jl provides the foundational `Network{T}` type that serves as the base data structure for all other StatNet Julia packages. It implements the Graphs.jl `AbstractGraph` interface while adding support for vertex, edge, and network-level attributes.

This package is a Julia port of the R `network` package from the StatNet collection.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/statistical-network-analysis-with-Julia/Network.jl")
```

## Features

- **Network type**: `Network{T}` implementing `AbstractGraph` interface
- **Attributes**: Vertex, edge, and network-level attribute storage
- **Flexibility**: Support for directed/undirected, bipartite, loops, multiple edges
- **Coercion**: Convert to/from matrices and edge lists
- **I/O**: Read/write Pajek and GraphML formats

## Quick Start

```julia
using Network

# Create a directed network with 5 vertices
net = Network{Int}(; n=5, directed=true)

# Add edges
add_edge!(net, 1, 2)
add_edge!(net, 2, 3)
add_edge!(net, 3, 1)

# Set vertex attributes
set_vertex_attribute!(net, 1, :name, "Alice")
set_vertex_attribute!(net, 2, :name, "Bob")

# Set edge attributes
set_edge_attribute!(net, 1, 2, :weight, 0.5)

# Query network
println("Vertices: ", nv(net))
println("Edges: ", ne(net))
println("Directed: ", is_directed(net))
```

## Network Creation

```julia
# Empty network
net = Network{Int}(; n=10)

# From adjacency matrix
mat = [0 1 0; 1 0 1; 0 1 0]
net = network_from_matrix(mat)

# From edge list
edges = [(1, 2), (2, 3), (3, 1)]
net = network_from_edgelist(edges, 3)
```

## Attributes

```julia
# Vertex attributes
set_vertex_attribute!(net, v, :attr_name, value)
val = get_vertex_attribute(net, :attr_name)  # Returns Dict

# Edge attributes
set_edge_attribute!(net, i, j, :attr_name, value)
val = get_edge_attribute(net, :attr_name)  # Returns Dict

# Network attributes
set_network_attribute!(net, :attr_name, value)
val = get_network_attribute(net, :attr_name)
```

## Conversion

```julia
# To adjacency matrix
mat = as_matrix(net)

# To edge list
edges = as_edgelist(net)

# To Graphs.jl SimpleGraph
g = SimpleDiGraph(net)
```

## I/O

```julia
# Pajek format
net = read_pajek("network.net")
write_pajek(net, "output.net")

# GraphML format
write_graphml(net, "network.graphml")
```

## Graphs.jl Compatibility

Network.jl implements the full `AbstractGraph` interface:

```julia
using Graphs

nv(net)           # Number of vertices
ne(net)           # Number of edges
vertices(net)     # Vertex iterator
edges(net)        # Edge iterator
neighbors(net, v) # Neighbors of vertex v
has_edge(net, i, j)
add_edge!(net, i, j)
rem_edge!(net, i, j)
```

## Documentation

For more detailed documentation, see:

- [Stable Documentation](https://statistical-network-analysis-with-Julia.github.io/Network.jl/stable/)
- [Development Documentation](https://statistical-network-analysis-with-Julia.github.io/Network.jl/dev/)

## References

1. Butts, C.T. (2008). network: A Package for Managing Relational Data in R. *Journal of Statistical Software*, 24(2), 1-36.

2. Butts, C.T. (2024). network: Classes for Relational Data. R package. [https://cran.r-project.org/package=network](https://cran.r-project.org/package=network)

## License

MIT License - see [LICENSE](LICENSE) for details.
