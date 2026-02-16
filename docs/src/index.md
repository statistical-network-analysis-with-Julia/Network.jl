# Network.jl

*Network data structures for Julia*

A Julia package providing network (graph) data structures with rich attribute support, designed for statistical network analysis.

## Overview

Network.jl is a Julia port of the [network](https://cran.r-project.org/web/packages/network/) package from the [StatNet](https://statnet.org/) suite for R. It provides a `Network` type that implements the [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) `AbstractGraph` interface while adding vertex, edge, and network-level attributes -- mirroring the functionality that makes R's `network` class the backbone of the StatNet ecosystem.

Network.jl is the foundational package in the [Statistical Network Analysis with Julia](https://github.com/Statistical-network-analysis-with-Julia) collection. Other packages such as [ERGM.jl](https://github.com/Statistical-network-analysis-with-Julia/ERGM.jl) and [SNA.jl](https://github.com/Statistical-network-analysis-with-Julia/SNA.jl) build on top of Network.jl.

### What is a Network?

A network (or graph) is a data structure representing relationships between entities:

```text
Alice --- Bob --- Carol
  \               /
   \--- David ---/
```

Entities are called **vertices** (or nodes) and relationships are called **edges** (or ties, links). Networks can be directed (edges have a sender and receiver) or undirected (edges are symmetric).

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Network** | A collection of vertices connected by edges, with optional attributes |
| **Vertex** | An entity in the network (person, organization, gene, etc.) |
| **Edge** | A relationship between two vertices (friendship, trade, interaction) |
| **Attribute** | Metadata attached to vertices, edges, or the network itself |
| **Graph Interface** | Compatibility with Graphs.jl algorithms via `AbstractGraph` |

### Applications

Network.jl is designed for use in:

- **Social network analysis**: Representing friendship, communication, and collaboration networks
- **Organizational studies**: Modeling inter- and intra-organizational ties
- **Epidemiology**: Contact networks for disease transmission
- **Biology**: Protein-protein interaction networks, gene regulatory networks
- **Economics**: Trade networks, financial transaction graphs
- **Political science**: Alliance networks, legislative co-sponsorship

## Features

- **Graphs.jl interface**: All Graphs.jl algorithms (shortest paths, centrality, connectivity, etc.) work directly on `Network` objects
- **Vertex, edge, and network attributes**: Store arbitrary metadata at every level, matching R's `network` class
- **Directed and undirected networks**: Full support for both, with correct edge counting and neighbor queries
- **Bipartite (two-mode) networks**: First-class support for bipartite structures via `BipartiteNetwork`
- **Matrix, edge list, and DataFrame conversion**: Convert to and from adjacency matrices, edge lists, and DataFrames
- **Pajek I/O**: Read and write Pajek `.net` files, the standard interchange format in network analysis
- **GraphML export**: Write networks in GraphML XML format
- **Sparse matrix support**: Convert large networks to sparse adjacency matrices for efficient computation

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/Statistical-network-analysis-with-Julia/Network.jl")
```

Or for development:

```julia
using Pkg
Pkg.develop(path="/path/to/Network.jl")
```

## Quick Start

```julia
using Network

# Create a directed network with 5 vertices
net = Network(5)

# Add edges
add_edge!(net, 1, 2)
add_edge!(net, 1, 3)
add_edge!(net, 2, 3)
add_edge!(net, 3, 4)
add_edge!(net, 4, 5)

# Set vertex attributes
set_vertex_attribute!(net, :name,
    Dict(1 => "Alice", 2 => "Bob", 3 => "Carol", 4 => "David", 5 => "Eve"))

# Set edge attributes
set_edge_attribute!(net, :weight,
    Dict((1,2) => 1.0, (1,3) => 2.0, (2,3) => 1.5, (3,4) => 3.0, (4,5) => 0.5))

# Query the network
println("Vertices: ", nv(net))       # 5
println("Edges: ", ne(net))          # 5
println("Density: ", network_density(net))

# Get neighbors
println("Neighbors of 3: ", collect(neighbors(net, 3)))

# Convert to adjacency matrix
A = as_matrix(net)

# Convert to DataFrame
df = as_dataframe(net)
```

## Common Operations

| Task | Function |
|------|----------|
| Create a network | [`Network(n)`](@ref Network), [`network(n)`](@ref network) |
| Add/remove edges | [`add_edge!`](@ref), [`rem_edge!`](@ref) |
| Vertex attributes | [`set_vertex_attribute!`](@ref), [`get_vertex_attribute`](@ref) |
| Edge attributes | [`set_edge_attribute!`](@ref), [`get_edge_attribute`](@ref) |
| Network attributes | [`set_network_attribute!`](@ref), [`get_network_attribute`](@ref) |
| To adjacency matrix | [`as_matrix`](@ref) |
| To edge list | [`as_edgelist`](@ref) |
| To DataFrame | [`as_dataframe`](@ref) |
| From matrix | [`network_from_matrix`](@ref) |
| Read Pajek file | [`read_pajek`](@ref) |
| Write Pajek file | [`write_pajek`](@ref) |

## Documentation

```@contents
Pages = [
    "getting_started.md",
    "guide/construction.md",
    "guide/attributes.md",
    "guide/conversion.md",
    "guide/io.md",
    "api/types.md",
    "api/graph_interface.md",
    "api/attributes.md",
    "api/conversion.md",
]
Depth = 2
```

## Comparison with R's network Package

Network.jl mirrors the R `network` package API as closely as Julia idioms allow:

| R (network package) | Julia (Network.jl) |
|----------------------|--------------------|
| `network(n, directed=TRUE)` | `Network(n; directed=true)` |
| `network.size(net)` | `nv(net)` or `network_size(net)` |
| `network.edgecount(net)` | `ne(net)` or `network_edgecount(net)` |
| `network.density(net)` | `network_density(net)` |
| `net %v% "attr"` | `get_vertex_attribute(net, :attr)` |
| `net %e% "attr"` | `get_edge_attribute(net, :attr)` |
| `set.vertex.attribute(net, "a", v)` | `set_vertex_attribute!(net, :a, v)` |
| `as.matrix(net)` | `as_matrix(net)` |
| `as.edgelist(net)` | `as_edgelist(net)` |
| `read.paj("file.net")` | `read_pajek("file.net")` |

## References

1. Butts, C.T. (2008). network: A Package for Managing Relational Data in R. *Journal of Statistical Software*, 24(2), 1-36.

2. Butts, C.T. (2015). network: Classes for Relational Data. The Statnet Project. R package version 1.13.0.

3. Handcock, M.S., Hunter, D.R., Butts, C.T., Goodreau, S.M., Morris, M. (2008). statnet: Software Tools for the Representation, Visualization, Analysis and Simulation of Network Data. *Journal of Statistical Software*, 24(1), 1-11.

4. Csardi, G., Nepusz, T. (2006). The igraph software package for complex network research. *InterJournal*, Complex Systems, 1695.
