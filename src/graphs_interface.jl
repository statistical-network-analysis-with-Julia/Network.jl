# Graphs.jl AbstractGraph interface implementation for Network types.
#
# This allows Network objects to be used with all Graphs.jl algorithms
# and functions seamlessly.

import Graphs: nv, ne, vertices, edges, has_vertex, has_edge
import Graphs: is_directed, add_vertex!, add_edge!, rem_vertex!, rem_edge!
import Graphs: neighbors, inneighbors, outneighbors
import Graphs: edgetype, SimpleEdge

# ============================================================================
# Basic Graph Properties
# ============================================================================

"""
    nv(net::Network) -> Int

Return the number of vertices in the network.
"""
Graphs.nv(net::Network) = Graphs.nv(net.graph)
Graphs.nv(net::BipartiteNetwork) = Graphs.nv(net.network.graph)

"""
    ne(net::Network) -> Int

Return the number of edges in the network.
For undirected networks, each edge is counted once.
"""
function Graphs.ne(net::Network)
    n = Graphs.ne(net.graph)
    # For undirected networks stored as digraphs, divide by 2
    return net.directed ? n : n ÷ 2
end
Graphs.ne(net::BipartiteNetwork) = Graphs.ne(net.network)

"""
    vertices(net::Network) -> iterator

Return an iterator over all vertices.
"""
Graphs.vertices(net::Network) = Graphs.vertices(net.graph)
Graphs.vertices(net::BipartiteNetwork) = Graphs.vertices(net.network.graph)

"""
    edges(net::Network) -> iterator

Return an iterator over all edges.
"""
function Graphs.edges(net::Network)
    if net.directed
        return Graphs.edges(net.graph)
    else
        # For undirected, only return edges where src <= dst to avoid duplicates
        return (e for e in Graphs.edges(net.graph) if src(e) <= dst(e))
    end
end
Graphs.edges(net::BipartiteNetwork) = Graphs.edges(net.network)

"""
    has_vertex(net::Network, v) -> Bool

Check if vertex v exists in the network.
"""
Graphs.has_vertex(net::Network, v) = Graphs.has_vertex(net.graph, v)
Graphs.has_vertex(net::BipartiteNetwork, v) = Graphs.has_vertex(net.network.graph, v)

"""
    has_edge(net::Network, i, j) -> Bool

Check if edge (i, j) exists in the network.
"""
function Graphs.has_edge(net::Network, i, j)
    if net.directed
        return Graphs.has_edge(net.graph, i, j)
    else
        return Graphs.has_edge(net.graph, i, j) || Graphs.has_edge(net.graph, j, i)
    end
end
Graphs.has_edge(net::BipartiteNetwork, i, j) = Graphs.has_edge(net.network, i, j)

"""
    is_directed(net::Network) -> Bool

Check if the network is directed.
"""
Graphs.is_directed(net::Network) = net.directed
Graphs.is_directed(::Type{<:Network}) = true  # Internal storage is always directed
Graphs.is_directed(net::BipartiteNetwork) = net.network.directed

"""
    is_bipartite(net::Network) -> Bool

Check if the network is bipartite (two-mode).
"""
Graphs.is_bipartite(net::Network) = !isnothing(net.bipartite)
Graphs.is_bipartite(net::BipartiteNetwork) = true

# ============================================================================
# Edge Type
# ============================================================================

Graphs.edgetype(net::Network{T}) where T = SimpleEdge{T}
Graphs.edgetype(net::BipartiteNetwork{T}) where T = SimpleEdge{T}

# ============================================================================
# Vertex Modification
# ============================================================================

"""
    add_vertex!(net::Network) -> Bool

Add a new vertex to the network. Returns true if successful.
"""
function Graphs.add_vertex!(net::Network)
    return Graphs.add_vertex!(net.graph)
end

"""
    add_vertices!(net::Network, n::Int) -> Int

Add n new vertices to the network. Returns the number of vertices added.
"""
function add_vertices!(net::Network, n::Int)
    added = 0
    for _ in 1:n
        if Graphs.add_vertex!(net.graph)
            added += 1
        end
    end
    return added
end

"""
    rem_vertex!(net::Network, v) -> Bool

Remove vertex v from the network. Returns true if successful.
Note: This will also remove all edges incident to v and update vertex attributes.
"""
function Graphs.rem_vertex!(net::Network{T}, v) where T
    if !has_vertex(net, v)
        return false
    end

    # Remove edges involving this vertex from edge attributes
    for attr in keys(net.edge_attrs)
        for edge in collect(keys(net.edge_attrs[attr]))
            if edge[1] == v || edge[2] == v
                delete!(net.edge_attrs[attr], edge)
            end
        end
    end

    # Remove vertex from vertex attributes
    for attr in keys(net.vertex_attrs)
        delete!(net.vertex_attrs[attr], T(v))
    end

    # Remove from graph (this also removes incident edges)
    return Graphs.rem_vertex!(net.graph, v)
end

# ============================================================================
# Edge Modification
# ============================================================================

"""
    add_edge!(net::Network, i, j) -> Bool

Add edge (i, j) to the network. Returns true if successful.
For undirected networks, also adds (j, i).
"""
function Graphs.add_edge!(net::Network, i, j)
    # Check self-loop constraint
    if i == j && !net.loops
        return false
    end

    result = Graphs.add_edge!(net.graph, i, j)

    # For undirected networks, add reverse edge too
    if !net.directed && result
        Graphs.add_edge!(net.graph, j, i)
    end

    return result
end

"""
    add_edge!(net::Network, i, j, attrs::Dict) -> Bool

Add edge with attributes.
"""
function add_edge!(net::Network{T}, i, j, attrs::Dict{Symbol}) where T
    result = Graphs.add_edge!(net, i, j)
    if result
        edge = _canonical_edge(net, T(i), T(j))
        for (attr, val) in attrs
            if !haskey(net.edge_attrs, attr)
                net.edge_attrs[attr] = Dict{Tuple{T,T}, Any}()
            end
            net.edge_attrs[attr][edge] = val
        end
    end
    return result
end

"""
    add_edges!(net::Network, edges) -> Int

Add multiple edges. Returns the number of edges added.
"""
function add_edges!(net::Network, edge_list)
    added = 0
    for (i, j) in edge_list
        if Graphs.add_edge!(net, i, j)
            added += 1
        end
    end
    return added
end

"""
    rem_edge!(net::Network, i, j) -> Bool

Remove edge (i, j) from the network. Returns true if successful.
"""
function Graphs.rem_edge!(net::Network{T}, i, j) where T
    # Remove edge attributes
    edge = _canonical_edge(net, T(i), T(j))
    for attr in keys(net.edge_attrs)
        delete!(net.edge_attrs[attr], edge)
    end

    result = Graphs.rem_edge!(net.graph, i, j)

    # For undirected, also remove reverse edge
    if !net.directed
        Graphs.rem_edge!(net.graph, j, i)
    end

    return result
end

# ============================================================================
# Neighbors
# ============================================================================

"""
    neighbors(net::Network, v) -> iterator

Return neighbors of vertex v.
For directed networks, returns outgoing neighbors.
"""
function Graphs.neighbors(net::Network, v::Integer)
    if net.directed
        return Graphs.outneighbors(net.graph, v)
    else
        # For undirected, outneighbors gives all neighbors since we store both directions
        return Graphs.outneighbors(net.graph, v)
    end
end

"""
    inneighbors(net::Network, v) -> iterator

Return incoming neighbors of vertex v.
"""
Graphs.inneighbors(net::Network, v) = Graphs.inneighbors(net.graph, v)

"""
    outneighbors(net::Network, v) -> iterator

Return outgoing neighbors of vertex v.
"""
Graphs.outneighbors(net::Network, v) = Graphs.outneighbors(net.graph, v)

# ============================================================================
# Additional Utility Functions
# ============================================================================

"""
    network_size(net::Network) -> Int

Return the number of vertices. Alias for nv() to match R's network.size().
"""
network_size(net::AbstractNetwork) = nv(net)

"""
    network_edgecount(net::Network) -> Int

Return the number of edges. Alias for ne() to match R's network.edgecount().
"""
network_edgecount(net::AbstractNetwork) = ne(net)

"""
    network_density(net::Network) -> Float64

Calculate network density (proportion of possible edges that exist).
"""
function network_density(net::Network)
    n = nv(net)
    if n <= 1
        return 0.0
    end

    m = ne(net)
    if net.directed
        max_edges = net.loops ? n * n : n * (n - 1)
    else
        max_edges = net.loops ? n * (n + 1) ÷ 2 : n * (n - 1) ÷ 2
    end

    return m / max_edges
end

"""
    get_neighborhood(net::Network, v, order::Int=1) -> Set

Get the neighborhood of vertex v up to the specified order (distance).
"""
function get_neighborhood(net::Network{T}, v, order::Int=1) where T
    neighborhood = Set{T}([T(v)])
    frontier = Set{T}([T(v)])

    for _ in 1:order
        new_frontier = Set{T}()
        for u in frontier
            for w in neighbors(net, u)
                if !(w in neighborhood)
                    push!(new_frontier, w)
                    push!(neighborhood, w)
                end
            end
        end
        frontier = new_frontier
        if isempty(frontier)
            break
        end
    end

    return neighborhood
end

"""
    get_induced_subgraph(net::Network, vlist) -> Network

Create a new network containing only the specified vertices and edges between them.
"""
function get_induced_subgraph(net::Network{T}, vlist) where T
    vset = Set(vlist)
    n = length(vlist)

    # Create mapping from old to new vertex IDs
    old_to_new = Dict{T, T}(T(v) => T(i) for (i, v) in enumerate(vlist))

    # Create new network
    sub = Network{T}(; n=n, directed=net.directed, loops=net.loops)

    # Add edges
    for e in edges(net)
        i, j = src(e), dst(e)
        if i in vset && j in vset
            add_edge!(sub, old_to_new[i], old_to_new[j])
        end
    end

    # Copy vertex attributes
    for (attr, vals) in net.vertex_attrs
        new_vals = Dict{T, Any}()
        for (v, val) in vals
            if v in vset
                new_vals[old_to_new[v]] = val
            end
        end
        if !isempty(new_vals)
            sub.vertex_attrs[attr] = new_vals
        end
    end

    # Copy edge attributes
    for (attr, vals) in net.edge_attrs
        new_vals = Dict{Tuple{T,T}, Any}()
        for ((i, j), val) in vals
            if i in vset && j in vset
                new_edge = _canonical_edge(sub, old_to_new[i], old_to_new[j])
                new_vals[new_edge] = val
            end
        end
        if !isempty(new_vals)
            sub.edge_attrs[attr] = new_vals
        end
    end

    # Copy network attributes
    for (attr, val) in net.network_attrs
        sub.network_attrs[attr] = val
    end

    return sub
end

"""
    permute_vertices(net::Network, perm::Vector) -> Network

Create a new network with vertices permuted according to the given permutation.
"""
function permute_vertices(net::Network{T}, perm::Vector) where T
    n = nv(net)
    length(perm) == n || throw(ArgumentError("Permutation length must match number of vertices"))

    # Create inverse permutation for mapping old -> new
    inv_perm = zeros(T, n)
    for (new_id, old_id) in enumerate(perm)
        inv_perm[old_id] = T(new_id)
    end

    # Create new network
    new_net = Network{T}(; n=n, directed=net.directed, loops=net.loops,
                         bipartite=net.bipartite, multiple=net.multiple, hyper=net.hyper)

    # Add permuted edges
    for e in edges(net)
        add_edge!(new_net, inv_perm[src(e)], inv_perm[dst(e)])
    end

    # Permute vertex attributes
    for (attr, vals) in net.vertex_attrs
        new_vals = Dict{T, Any}(inv_perm[k] => v for (k, v) in vals)
        new_net.vertex_attrs[attr] = new_vals
    end

    # Permute edge attributes
    for (attr, vals) in net.edge_attrs
        new_vals = Dict{Tuple{T,T}, Any}()
        for ((i, j), v) in vals
            new_edge = _canonical_edge(new_net, inv_perm[i], inv_perm[j])
            new_vals[new_edge] = v
        end
        new_net.edge_attrs[attr] = new_vals
    end

    # Copy network attributes
    for (attr, val) in net.network_attrs
        new_net.network_attrs[attr] = val
    end

    return new_net
end
