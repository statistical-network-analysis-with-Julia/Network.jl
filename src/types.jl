"""
Core network types for the Network.jl package.

Provides network data structures that implement Graphs.jl's AbstractGraph
interface while supporting vertex/edge attributes like R's network package.
"""

"""
    AbstractNetwork{T} <: Graphs.AbstractGraph{T}

Abstract base type for all network types. Extends Graphs.jl's AbstractGraph
to provide StatNet-compatible network functionality.
"""
abstract type AbstractNetwork{T<:Integer} <: Graphs.AbstractGraph{T} end

"""
    Network{T}

Core network data structure representing a network with optional vertex and edge attributes.

Mirrors R's network class from the statnet network package, while implementing
Graphs.jl's AbstractGraph interface for interoperability with the Julia graph ecosystem.

# Type Parameters
- `T`: Vertex ID type (typically Int)

# Fields
- `graph::SimpleDiGraph{T}`: Underlying directed graph structure
- `directed::Bool`: Whether edges are directed (affects interpretation, not storage)
- `bipartite::Union{Nothing, Int}`: Number of vertices in first mode if bipartite, nothing otherwise
- `loops::Bool`: Whether self-loops are allowed
- `multiple::Bool`: Whether multiple edges between same vertices are allowed (not fully supported)
- `hyper::Bool`: Whether hyperedges are allowed (not fully supported)
- `vertex_attrs::Dict{Symbol, Dict{T, Any}}`: Vertex attributes by name
- `edge_attrs::Dict{Symbol, Dict{Tuple{T,T}, Any}}`: Edge attributes by vertex pair
- `network_attrs::Dict{Symbol, Any}`: Network-level attributes

# Example
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
"""
mutable struct Network{T<:Integer} <: AbstractNetwork{T}
    graph::SimpleDiGraph{T}
    directed::Bool
    bipartite::Union{Nothing, Int}
    loops::Bool
    multiple::Bool
    hyper::Bool
    vertex_attrs::Dict{Symbol, Dict{T, Any}}
    edge_attrs::Dict{Symbol, Dict{Tuple{T,T}, Any}}
    network_attrs::Dict{Symbol, Any}

    function Network{T}(;
        n::Int = 0,
        directed::Bool = true,
        bipartite::Union{Nothing, Int} = nothing,
        loops::Bool = false,
        multiple::Bool = false,
        hyper::Bool = false
    ) where T<:Integer
        g = SimpleDiGraph{T}(n)
        new{T}(
            g,
            directed,
            bipartite,
            loops,
            multiple,
            hyper,
            Dict{Symbol, Dict{T, Any}}(),
            Dict{Symbol, Dict{Tuple{T,T}, Any}}(),
            Dict{Symbol, Any}()
        )
    end
end

# Convenience constructor with default Int type
function Network(n::Int=0; kwargs...)
    Network{Int}(; n=n, kwargs...)
end

"""
    network(n::Int; kwargs...) -> Network

Create a new network with `n` vertices. Alias for Network constructor
to match R's network() function.

# Keyword Arguments
- `directed::Bool=true`: Whether the network is directed
- `bipartite::Union{Nothing,Int}=nothing`: Number of vertices in first mode if bipartite
- `loops::Bool=false`: Whether self-loops are allowed
- `multiple::Bool=false`: Whether multiple edges are allowed
- `hyper::Bool=false`: Whether hyperedges are allowed

# Example
```julia
net = network(10; directed=false)
```
"""
network(n::Int=0; kwargs...) = Network(n; kwargs...)

"""
    network_initialize(n::Int; kwargs...) -> Network

Initialize an empty network with `n` vertices. Alias matching R's network.initialize().
"""
network_initialize(n::Int; kwargs...) = Network(n; kwargs...)

"""
    BipartiteNetwork{T}

A bipartite (two-mode) network with distinct vertex sets.

# Fields
- `network::Network{T}`: Underlying network
- `n_mode1::Int`: Number of vertices in the first mode
- `n_mode2::Int`: Number of vertices in the second mode

Vertices 1:n_mode1 are in the first mode, (n_mode1+1):(n_mode1+n_mode2) are in the second mode.
"""
struct BipartiteNetwork{T<:Integer} <: AbstractNetwork{T}
    network::Network{T}
    n_mode1::Int
    n_mode2::Int

    function BipartiteNetwork{T}(n_mode1::Int, n_mode2::Int; kwargs...) where T<:Integer
        net = Network{T}(; n=n_mode1 + n_mode2, bipartite=n_mode1, kwargs...)
        new{T}(net, n_mode1, n_mode2)
    end
end

BipartiteNetwork(n_mode1::Int, n_mode2::Int; kwargs...) = BipartiteNetwork{Int}(n_mode1, n_mode2; kwargs...)

# Helper function to get canonical edge representation
function _canonical_edge(net::Network{T}, i::T, j::T) where T
    if net.directed
        return (i, j)
    else
        # For undirected networks, use canonical ordering
        return minmax(i, j)
    end
end

# Display methods
function Base.show(io::IO, net::Network{T}) where T
    dir_str = net.directed ? "directed" : "undirected"
    bip_str = isnothing(net.bipartite) ? "" : " bipartite"
    println(io, "Network{$T}:$bip_str $dir_str network")
    println(io, "  Vertices: $(nv(net))")
    println(io, "  Edges: $(ne(net))")

    n_vattrs = length(net.vertex_attrs)
    n_eattrs = length(net.edge_attrs)
    n_nattrs = length(net.network_attrs)

    if n_vattrs > 0
        println(io, "  Vertex attributes: $(join(keys(net.vertex_attrs), ", "))")
    end
    if n_eattrs > 0
        println(io, "  Edge attributes: $(join(keys(net.edge_attrs), ", "))")
    end
    if n_nattrs > 0
        println(io, "  Network attributes: $(join(keys(net.network_attrs), ", "))")
    end
end

function Base.show(io::IO, net::BipartiteNetwork{T}) where T
    println(io, "BipartiteNetwork{$T}:")
    println(io, "  Mode 1 vertices: $(net.n_mode1)")
    println(io, "  Mode 2 vertices: $(net.n_mode2)")
    println(io, "  Edges: $(ne(net))")
end
