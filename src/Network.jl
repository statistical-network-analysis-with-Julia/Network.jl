"""
    Network.jl - Network Data Structures for Julia

A Julia package providing network data structures compatible with the StatNet
ecosystem. Implements the Graphs.jl AbstractGraph interface while providing
StatNet-compatible features like vertex/edge attributes.

This is the foundational package upon which SNA.jl, ERGM.jl, and other
Statistical Network Analysis packages are built.
"""
module Network

using Graphs
using SparseArrays
using LinearAlgebra
using DataFrames

# Core types
export AbstractNetwork, Network, BipartiteNetwork

# Graph interface (re-exported from Graphs.jl for convenience)
export nv, ne, vertices, edges, has_vertex, has_edge
export neighbors, inneighbors, outneighbors
export is_directed, is_bipartite

# Network construction
export network, network_initialize
export add_vertex!, add_vertices!, rem_vertex!
export add_edge!, add_edges!, rem_edge!

# Attribute handling
export get_vertex_attribute, set_vertex_attribute!, delete_vertex_attribute!
export get_edge_attribute, set_edge_attribute!, delete_edge_attribute!
export get_network_attribute, set_network_attribute!, delete_network_attribute!
export list_vertex_attributes, list_edge_attributes, list_network_attributes

# Coercion and conversion
export as_matrix, as_adjacency_matrix, as_edgelist, as_dataframe
export network_from_matrix, network_from_edgelist

# I/O
export read_pajek, write_pajek

# Utilities
export network_size, network_density, network_edgecount
export permute_vertices, get_neighborhood, get_induced_subgraph

# Include source files
include("types.jl")
include("attributes.jl")
include("graphs_interface.jl")
include("coercion.jl")
include("io.jl")

end # module
