# Coercion and conversion functions for Network objects.
#
# Provides functions to convert networks to/from matrices, edge lists,
# and DataFrames, similar to R's as.matrix.network, as.edgelist, etc.

using SparseArrays

# ============================================================================
# Network to Matrix
# ============================================================================

"""
    as_matrix(net::Network; attr::Union{Symbol,Nothing}=nothing, sparse::Bool=false) -> Matrix

Convert network to an adjacency matrix.

# Arguments
- `net::Network`: The network to convert
- `attr::Union{Symbol,Nothing}=nothing`: Edge attribute to use as values (nothing = binary)
- `sparse::Bool=false`: Return a sparse matrix instead of dense

# Example
```julia
A = as_matrix(net)
W = as_matrix(net; attr=:weight)
```
"""
function as_matrix(net::Network{T}; attr::Union{Symbol,Nothing}=nothing, sparse::Bool=false) where T
    n = nv(net)

    if sparse
        I = Int[]
        J = Int[]
        V = Float64[]

        for e in Graphs.edges(net.graph)
            i, j = src(e), dst(e)
            push!(I, i)
            push!(J, j)
            if isnothing(attr)
                push!(V, 1.0)
            else
                edge = _canonical_edge(net, T(i), T(j))
                val = get(get(net.edge_attrs, attr, Dict()), edge, 0.0)
                push!(V, Float64(val))
            end
        end

        return SparseArrays.sparse(I, J, V, n, n)
    else
        A = zeros(Float64, n, n)

        for e in Graphs.edges(net.graph)
            i, j = src(e), dst(e)
            if isnothing(attr)
                A[i, j] = 1.0
            else
                edge = _canonical_edge(net, T(i), T(j))
                A[i, j] = Float64(get(get(net.edge_attrs, attr, Dict()), edge, 0.0))
            end
        end

        return A
    end
end

"""
    as_adjacency_matrix(net::Network; kwargs...) -> Matrix

Alias for as_matrix. Matches R's as.matrix.network with matrix.type="adjacency".
"""
as_adjacency_matrix(net::Network; kwargs...) = as_matrix(net; kwargs...)

# ============================================================================
# Network to Edge List
# ============================================================================

"""
    as_edgelist(net::Network; attrs::Vector{Symbol}=Symbol[]) -> Matrix

Convert network to an edge list (n_edges x 2 matrix).

# Arguments
- `net::Network`: The network to convert
- `attrs::Vector{Symbol}`: Edge attributes to include as additional columns

# Returns
If no attrs: Matrix{Int} of size (n_edges, 2)
If attrs: Returns a tuple (edgelist::Matrix{Int}, attr_values::Dict{Symbol, Vector})
"""
function as_edgelist(net::Network{T}; attrs::Vector{Symbol}=Symbol[]) where T
    edge_list = Tuple{T, T}[]

    for e in edges(net)
        push!(edge_list, (src(e), dst(e)))
    end

    n_edges = length(edge_list)

    if isempty(attrs)
        result = Matrix{T}(undef, n_edges, 2)
        for (idx, (i, j)) in enumerate(edge_list)
            result[idx, 1] = i
            result[idx, 2] = j
        end
        return result
    else
        # Include attributes
        result = Matrix{T}(undef, n_edges, 2)
        attr_vals = Dict{Symbol, Vector}()

        for attr in attrs
            attr_vals[attr] = Vector{Any}(undef, n_edges)
        end

        for (idx, (i, j)) in enumerate(edge_list)
            result[idx, 1] = i
            result[idx, 2] = j
            edge = _canonical_edge(net, i, j)
            for attr in attrs
                attr_vals[attr][idx] = get(get(net.edge_attrs, attr, Dict()), edge, missing)
            end
        end

        return (result, attr_vals)
    end
end

# ============================================================================
# Network to DataFrame
# ============================================================================

"""
    as_dataframe(net::Network; vertices::Bool=false, attrs::Vector{Symbol}=Symbol[]) -> DataFrame

Convert network to a DataFrame.

# Arguments
- `net::Network`: The network to convert
- `vertices::Bool=false`: If true, return vertex DataFrame instead of edge DataFrame
- `attrs::Vector{Symbol}`: Attributes to include (defaults to all)

# Example
```julia
# Edge DataFrame
edge_df = as_dataframe(net)

# Vertex DataFrame
vertex_df = as_dataframe(net; vertices=true)
```
"""
function as_dataframe(net::Network{T}; vertices::Bool=false, attrs::Vector{Symbol}=Symbol[]) where T
    if vertices
        # Vertex DataFrame
        n = nv(net)
        df = DataFrame(vertex = collect(1:n))

        attrs_to_include = isempty(attrs) ? list_vertex_attributes(net) : attrs
        for attr in attrs_to_include
            vals = get_vertex_attribute(net, attr)
            df[!, attr] = [get(vals, T(i), missing) for i in 1:n]
        end

        return df
    else
        # Edge DataFrame
        edge_list = as_edgelist(net)
        n_edges = size(edge_list, 1)

        df = DataFrame(
            source = edge_list[:, 1],
            target = edge_list[:, 2]
        )

        attrs_to_include = isempty(attrs) ? list_edge_attributes(net) : attrs
        for attr in attrs_to_include
            edge_vals = get_edge_attribute(net, attr)
            df[!, attr] = [get(edge_vals, _canonical_edge(net, edge_list[i, 1], edge_list[i, 2]), missing)
                          for i in 1:n_edges]
        end

        return df
    end
end

# ============================================================================
# Matrix to Network
# ============================================================================

"""
    network_from_matrix(A::AbstractMatrix; directed::Bool=true, loops::Bool=false,
                        ignore_eval=nothing, names_eval=nothing) -> Network

Create a network from an adjacency matrix.

# Arguments
- `A::AbstractMatrix`: Adjacency matrix
- `directed::Bool=true`: Whether to create a directed network
- `loops::Bool=false`: Whether to allow self-loops
- `ignore_eval`: Function to test if a value should be ignored (default: ==(0))
- `names_eval`: Optional vertex names

# Example
```julia
A = [0 1 1; 1 0 0; 1 0 0]
net = network_from_matrix(A; directed=false)
```
"""
function network_from_matrix(A::AbstractMatrix;
                             directed::Bool=true,
                             loops::Bool=false,
                             ignore_eval=nothing,
                             names_eval=nothing,
                             attr::Symbol=:weight)
    n = size(A, 1)
    size(A, 1) == size(A, 2) || throw(ArgumentError("Matrix must be square"))

    # Default: ignore zeros
    should_ignore = isnothing(ignore_eval) ? (x -> x == 0) : ignore_eval

    net = Network(n; directed=directed, loops=loops)

    # Add vertex names if provided
    if !isnothing(names_eval)
        set_vertex_attribute!(net, :vertex_names, names_eval)
    end

    # Determine if matrix is binary or weighted
    is_binary = all(x -> x == 0 || x == 1, A)

    for i in 1:n
        j_start = directed ? 1 : i  # For undirected, only upper triangle
        for j in j_start:n
            val = A[i, j]
            if !should_ignore(val)
                if !loops && i == j
                    continue
                end
                add_edge!(net, i, j)

                # Store weight if not binary
                if !is_binary
                    set_edge_attribute!(net, attr, i, j, val)
                end
            end
        end
    end

    return net
end

# ============================================================================
# Edge List to Network
# ============================================================================

"""
    network_from_edgelist(edges; n::Union{Int,Nothing}=nothing,
                          directed::Bool=true, loops::Bool=false) -> Network

Create a network from an edge list.

# Arguments
- `edges`: Edge list as Matrix (n x 2) or Vector of tuples
- `n::Union{Int,Nothing}`: Number of vertices (auto-detected if nothing)
- `directed::Bool=true`: Whether to create a directed network
- `loops::Bool=false`: Whether to allow self-loops

# Example
```julia
edges = [(1, 2), (2, 3), (3, 1)]
net = network_from_edgelist(edges)
```
"""
function network_from_edgelist(edges;
                               n::Union{Int,Nothing}=nothing,
                               directed::Bool=true,
                               loops::Bool=false)
    # Convert to vector of tuples if matrix
    if edges isa AbstractMatrix
        edge_tuples = [(edges[i, 1], edges[i, 2]) for i in 1:size(edges, 1)]
    else
        edge_tuples = collect(edges)
    end

    # Auto-detect n if not provided
    if isnothing(n)
        n = maximum(max(i, j) for (i, j) in edge_tuples)
    end

    net = Network(n; directed=directed, loops=loops)

    for (i, j) in edge_tuples
        add_edge!(net, i, j)
    end

    return net
end

"""
    network_from_dataframe(df::DataFrame; source::Symbol=:source, target::Symbol=:target,
                           directed::Bool=true, loops::Bool=false) -> Network

Create a network from a DataFrame with source and target columns.

# Arguments
- `df::DataFrame`: DataFrame with edge information
- `source::Symbol`: Column name for source vertices
- `target::Symbol`: Column name for target vertices
- `directed::Bool`: Whether to create a directed network
- `loops::Bool`: Whether to allow self-loops

# Example
```julia
df = DataFrame(source = [1, 2, 3], target = [2, 3, 1], weight = [1.0, 2.0, 1.5])
net = network_from_dataframe(df)
```
"""
function network_from_dataframe(df::DataFrame;
                                source::Symbol=:source,
                                target::Symbol=:target,
                                directed::Bool=true,
                                loops::Bool=false)
    edges = [(df[i, source], df[i, target]) for i in 1:nrow(df)]
    n = maximum(max(e[1], e[2]) for e in edges)

    net = Network(n; directed=directed, loops=loops)

    # Add edges
    for (i, j) in edges
        add_edge!(net, i, j)
    end

    # Add edge attributes from other columns
    other_cols = setdiff(names(df), [string(source), string(target)])
    for col in other_cols
        attr = Symbol(col)
        for (idx, (i, j)) in enumerate(edges)
            set_edge_attribute!(net, attr, i, j, df[idx, col])
        end
    end

    return net
end
