"""
Attribute handling for Network objects.

Provides functions to get, set, list, and delete vertex, edge, and network-level
attributes, similar to R's network package attribute functions.
"""

# ============================================================================
# Vertex Attributes
# ============================================================================

"""
    get_vertex_attribute(net::Network, attr::Symbol) -> Dict

Get a vertex attribute by name. Returns a Dict mapping vertex IDs to values.

# Example
```julia
names = get_vertex_attribute(net, :name)
```
"""
function get_vertex_attribute(net::Network{T}, attr::Symbol) where T
    return get(net.vertex_attrs, attr, Dict{T, Any}())
end

"""
    get_vertex_attribute(net::Network, attr::Symbol, v::Integer) -> Any

Get the attribute value for a specific vertex.
"""
function get_vertex_attribute(net::Network{T}, attr::Symbol, v::Integer) where T
    attrs = get(net.vertex_attrs, attr, nothing)
    if isnothing(attrs)
        return nothing
    end
    return get(attrs, T(v), nothing)
end

"""
    set_vertex_attribute!(net::Network, attr::Symbol, values::Dict)

Set a vertex attribute from a Dict mapping vertex IDs to values.

# Example
```julia
set_vertex_attribute!(net, :name, Dict(1 => "Alice", 2 => "Bob"))
```
"""
function set_vertex_attribute!(net::Network{T}, attr::Symbol, values::Dict) where T
    if !haskey(net.vertex_attrs, attr)
        net.vertex_attrs[attr] = Dict{T, Any}()
    end
    for (k, v) in values
        net.vertex_attrs[attr][T(k)] = v
    end
    return net
end

"""
    set_vertex_attribute!(net::Network, attr::Symbol, v::Integer, value)

Set the attribute value for a specific vertex.
"""
function set_vertex_attribute!(net::Network{T}, attr::Symbol, v::Integer, value) where T
    if !haskey(net.vertex_attrs, attr)
        net.vertex_attrs[attr] = Dict{T, Any}()
    end
    net.vertex_attrs[attr][T(v)] = value
    return net
end

"""
    set_vertex_attribute!(net::Network, attr::Symbol, values::Vector)

Set a vertex attribute from a Vector (assumes values are in vertex order 1:n).
"""
function set_vertex_attribute!(net::Network{T}, attr::Symbol, values::Vector) where T
    length(values) == nv(net) || throw(ArgumentError("Vector length must match number of vertices"))
    net.vertex_attrs[attr] = Dict{T, Any}(T(i) => v for (i, v) in enumerate(values))
    return net
end

"""
    delete_vertex_attribute!(net::Network, attr::Symbol)

Delete a vertex attribute.
"""
function delete_vertex_attribute!(net::Network, attr::Symbol)
    delete!(net.vertex_attrs, attr)
    return net
end

"""
    list_vertex_attributes(net::Network) -> Vector{Symbol}

List all vertex attribute names.
"""
function list_vertex_attributes(net::Network)
    return collect(keys(net.vertex_attrs))
end

# ============================================================================
# Edge Attributes
# ============================================================================

"""
    get_edge_attribute(net::Network, attr::Symbol) -> Dict

Get an edge attribute by name. Returns a Dict mapping (source, target) tuples to values.
"""
function get_edge_attribute(net::Network{T}, attr::Symbol) where T
    return get(net.edge_attrs, attr, Dict{Tuple{T,T}, Any}())
end

"""
    get_edge_attribute(net::Network, attr::Symbol, i::Integer, j::Integer) -> Any

Get the attribute value for a specific edge.
"""
function get_edge_attribute(net::Network{T}, attr::Symbol, i::Integer, j::Integer) where T
    attrs = get(net.edge_attrs, attr, nothing)
    if isnothing(attrs)
        return nothing
    end
    edge = _canonical_edge(net, T(i), T(j))
    return get(attrs, edge, nothing)
end

"""
    set_edge_attribute!(net::Network, attr::Symbol, values::Dict)

Set an edge attribute from a Dict mapping (source, target) tuples to values.

# Example
```julia
set_edge_attribute!(net, :weight, Dict((1,2) => 1.5, (2,3) => 2.0))
```
"""
function set_edge_attribute!(net::Network{T}, attr::Symbol, values::Dict) where T
    if !haskey(net.edge_attrs, attr)
        net.edge_attrs[attr] = Dict{Tuple{T,T}, Any}()
    end
    for ((i, j), v) in values
        edge = _canonical_edge(net, T(i), T(j))
        net.edge_attrs[attr][edge] = v
    end
    return net
end

"""
    set_edge_attribute!(net::Network, attr::Symbol, i::Integer, j::Integer, value)

Set the attribute value for a specific edge.
"""
function set_edge_attribute!(net::Network{T}, attr::Symbol, i::Integer, j::Integer, value) where T
    if !haskey(net.edge_attrs, attr)
        net.edge_attrs[attr] = Dict{Tuple{T,T}, Any}()
    end
    edge = _canonical_edge(net, T(i), T(j))
    net.edge_attrs[attr][edge] = value
    return net
end

"""
    delete_edge_attribute!(net::Network, attr::Symbol)

Delete an edge attribute.
"""
function delete_edge_attribute!(net::Network, attr::Symbol)
    delete!(net.edge_attrs, attr)
    return net
end

"""
    list_edge_attributes(net::Network) -> Vector{Symbol}

List all edge attribute names.
"""
function list_edge_attributes(net::Network)
    return collect(keys(net.edge_attrs))
end

# ============================================================================
# Network Attributes
# ============================================================================

"""
    get_network_attribute(net::Network, attr::Symbol) -> Any

Get a network-level attribute by name.
"""
function get_network_attribute(net::Network, attr::Symbol)
    return get(net.network_attrs, attr, nothing)
end

"""
    set_network_attribute!(net::Network, attr::Symbol, value)

Set a network-level attribute.

# Example
```julia
set_network_attribute!(net, :title, "Friendship Network")
```
"""
function set_network_attribute!(net::Network, attr::Symbol, value)
    net.network_attrs[attr] = value
    return net
end

"""
    delete_network_attribute!(net::Network, attr::Symbol)

Delete a network-level attribute.
"""
function delete_network_attribute!(net::Network, attr::Symbol)
    delete!(net.network_attrs, attr)
    return net
end

"""
    list_network_attributes(net::Network) -> Vector{Symbol}

List all network-level attribute names.
"""
function list_network_attributes(net::Network)
    return collect(keys(net.network_attrs))
end

# ============================================================================
# Convenience indexing (similar to R's %v% and %e% operators)
# ============================================================================

# net[:v, :attr] for vertex attributes
# net[:e, :attr] for edge attributes
# net[:n, :attr] for network attributes

function Base.getindex(net::Network, ::Val{:v}, attr::Symbol)
    return get_vertex_attribute(net, attr)
end

function Base.getindex(net::Network, ::Val{:e}, attr::Symbol)
    return get_edge_attribute(net, attr)
end

function Base.getindex(net::Network, ::Val{:n}, attr::Symbol)
    return get_network_attribute(net, attr)
end

function Base.setindex!(net::Network, value, ::Val{:v}, attr::Symbol)
    set_vertex_attribute!(net, attr, value)
end

function Base.setindex!(net::Network, value, ::Val{:e}, attr::Symbol)
    set_edge_attribute!(net, attr, value)
end

function Base.setindex!(net::Network, value, ::Val{:n}, attr::Symbol)
    set_network_attribute!(net, attr, value)
end

# Shorthand using symbols: net[:vertex, :name] or net[:edge, :weight]
Base.getindex(net::Network, level::Symbol, attr::Symbol) = Base.getindex(net, Val(level), attr)
Base.setindex!(net::Network, value, level::Symbol, attr::Symbol) = Base.setindex!(net, value, Val(level), attr)
