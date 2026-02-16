# Attributes

Network.jl provides a rich attribute system for attaching metadata to vertices, edges, and the network itself. This mirrors the attribute functionality in R's `network` package, where vertex and edge attributes are central to statistical network analysis.

## Attribute Levels

Attributes exist at three levels:

| Level | Stored In | Key Type | Description |
|-------|-----------|----------|-------------|
| **Vertex** | `net.vertex_attrs` | `Symbol → Dict{T, Any}` | Per-vertex metadata (name, age, group) |
| **Edge** | `net.edge_attrs` | `Symbol → Dict{Tuple{T,T}, Any}` | Per-edge metadata (weight, type, date) |
| **Network** | `net.network_attrs` | `Symbol → Any` | Whole-network metadata (title, description) |

All attribute names are Julia `Symbol`s (e.g., `:name`, `:weight`, `:department`).

## Vertex Attributes

Vertex attributes store metadata about individual vertices (nodes) in the network.

### Setting Vertex Attributes

There are three ways to set vertex attributes:

#### From a Dict

Map vertex IDs to values:

```julia
using Network

net = Network(5)

# Set names for specific vertices
set_vertex_attribute!(net, :name,
    Dict(1 => "Alice", 2 => "Bob", 3 => "Carol"))

# Set ages
set_vertex_attribute!(net, :age,
    Dict(1 => 25, 2 => 30, 3 => 28, 4 => 35, 5 => 22))
```

You do not need to provide values for all vertices. Missing vertices will return `nothing` when queried.

#### From a Vector

Provide one value per vertex in order:

```julia
# Values are assigned to vertices 1, 2, ..., n
set_vertex_attribute!(net, :score, [0.8, 0.6, 0.9, 0.3, 0.7])
```

The vector length must exactly match `nv(net)`.

#### For a Single Vertex

```julia
set_vertex_attribute!(net, :role, 1, "manager")
set_vertex_attribute!(net, :role, 2, "analyst")
set_vertex_attribute!(net, :role, 3, "engineer")
```

### Getting Vertex Attributes

#### Get All Values

Returns a `Dict` mapping vertex IDs to values:

```julia
names = get_vertex_attribute(net, :name)
# Dict(1 => "Alice", 2 => "Bob", 3 => "Carol")

# Iterate
for (v, name) in names
    println("Vertex $v: $name")
end
```

#### Get a Single Value

```julia
name = get_vertex_attribute(net, :name, 1)
# "Alice"

# Returns nothing if the vertex has no value for this attribute
get_vertex_attribute(net, :name, 4)
# nothing
```

### Listing Vertex Attributes

```julia
attrs = list_vertex_attributes(net)
# [:name, :age, :score, :role]
```

### Deleting Vertex Attributes

```julia
# Remove the :score attribute entirely
delete_vertex_attribute!(net, :score)

list_vertex_attributes(net)
# [:name, :age, :role]
```

### Vertex Attribute Patterns

#### Categorical Attributes

Store group memberships:

```julia
set_vertex_attribute!(net, :department,
    Dict(1 => "Engineering", 2 => "Engineering",
         3 => "Marketing", 4 => "Sales", 5 => "Sales"))
```

#### Numeric Attributes

Store continuous measurements:

```julia
set_vertex_attribute!(net, :centrality, [0.45, 0.32, 0.61, 0.28, 0.15])
```

#### Boolean Attributes

Store binary flags:

```julia
set_vertex_attribute!(net, :is_manager,
    Dict(1 => true, 2 => false, 3 => false, 4 => true, 5 => false))
```

## Edge Attributes

Edge attributes store metadata about individual edges (ties) in the network.

### Setting Edge Attributes

#### From a Dict

Map `(source, target)` tuples to values:

```julia
net = Network(4)
add_edges!(net, [(1,2), (2,3), (3,4), (4,1)])

# Set edge weights
set_edge_attribute!(net, :weight,
    Dict((1,2) => 1.0, (2,3) => 2.5, (3,4) => 0.8, (4,1) => 1.2))

# Set edge types
set_edge_attribute!(net, :type,
    Dict((1,2) => :friendship, (2,3) => :collaboration,
         (3,4) => :mentorship, (4,1) => :friendship))
```

#### For a Single Edge

```julia
set_edge_attribute!(net, :weight, 1, 2, 3.5)
set_edge_attribute!(net, :created, 1, 2, "2024-01-15")
```

### Getting Edge Attributes

#### Get All Values

Returns a `Dict` mapping `(source, target)` tuples to values:

```julia
weights = get_edge_attribute(net, :weight)
# Dict((1,2) => 1.0, (2,3) => 2.5, (3,4) => 0.8, (4,1) => 1.2)

# Iterate
for ((i, j), w) in weights
    println("Edge ($i, $j): weight = $w")
end
```

#### Get a Single Value

```julia
w = get_edge_attribute(net, :weight, 1, 2)
# 1.0

# Returns nothing if the edge has no value for this attribute
get_edge_attribute(net, :weight, 2, 1)
# nothing (edge 2→1 does not exist in a directed network)
```

### Edge Attributes in Undirected Networks

For undirected networks, edge attributes use canonical ordering (`minmax(i, j)`), so the order of vertices does not matter:

```julia
net = Network(3; directed=false)
add_edge!(net, 1, 2)

# Both orders refer to the same edge
set_edge_attribute!(net, :weight, 1, 2, 5.0)
get_edge_attribute(net, :weight, 2, 1)  # 5.0  -- same edge
get_edge_attribute(net, :weight, 1, 2)  # 5.0  -- same edge
```

### Listing Edge Attributes

```julia
attrs = list_edge_attributes(net)
# [:weight, :type, :created]
```

### Deleting Edge Attributes

```julia
delete_edge_attribute!(net, :created)

list_edge_attributes(net)
# [:weight, :type]
```

### Adding Edges with Attributes

You can add an edge and set its attributes in one call:

```julia
add_edge!(net, 1, 3, Dict(:weight => 2.0, :type => :friendship))
```

## Network Attributes

Network-level attributes store metadata about the entire network.

### Setting Network Attributes

```julia
set_network_attribute!(net, :title, "Florentine Marriage Network")
set_network_attribute!(net, :collected, 2024)
set_network_attribute!(net, :source, "Padgett & Ansell (1993)")
set_network_attribute!(net, :notes, "Historical marriage ties among Florentine families")
```

### Getting Network Attributes

```julia
title = get_network_attribute(net, :title)
# "Florentine Marriage Network"

# Returns nothing if the attribute does not exist
get_network_attribute(net, :nonexistent)
# nothing
```

### Listing Network Attributes

```julia
attrs = list_network_attributes(net)
# [:title, :collected, :source, :notes]
```

### Deleting Network Attributes

```julia
delete_network_attribute!(net, :notes)

list_network_attributes(net)
# [:title, :collected, :source]
```

## Convenience Indexing

Network.jl provides bracket-style indexing that mirrors R's `%v%` and `%e%` operators:

### Reading Attributes

```julia
# Vertex attributes (level = :v)
net[:v, :name]   # equivalent to get_vertex_attribute(net, :name)

# Edge attributes (level = :e)
net[:e, :weight]  # equivalent to get_edge_attribute(net, :weight)

# Network attributes (level = :n)
net[:n, :title]   # equivalent to get_network_attribute(net, :title)
```

### Writing Attributes

```julia
# Set vertex attribute
net[:v, :name] = Dict(1 => "Alice", 2 => "Bob")

# Set edge attribute
net[:e, :weight] = Dict((1,2) => 1.0, (2,3) => 2.0)

# Set network attribute
net[:n, :title] = "My Network"
```

### R Comparison

| R Syntax | Julia Equivalent |
|----------|-----------------|
| `net %v% "name"` | `net[:v, :name]` |
| `net %e% "weight"` | `net[:e, :weight]` |
| `set.vertex.attribute(net, "name", value)` | `net[:v, :name] = value` |
| `set.edge.attribute(net, "weight", value)` | `net[:e, :weight] = value` |

## Attributes and Graph Operations

### Subgraph Extraction

When extracting an induced subgraph, vertex and edge attributes are preserved with remapped vertex IDs:

```julia
net = Network(5)
add_edges!(net, [(1,2), (2,3), (3,4), (4,5)])
set_vertex_attribute!(net, :name,
    Dict(1=>"A", 2=>"B", 3=>"C", 4=>"D", 5=>"E"))
set_edge_attribute!(net, :weight,
    Dict((1,2)=>1.0, (2,3)=>2.0, (3,4)=>3.0, (4,5)=>4.0))

sub = get_induced_subgraph(net, [2, 3, 4])
# Vertices are remapped: old 2→new 1, old 3→new 2, old 4→new 3

get_vertex_attribute(sub, :name)
# Dict(1=>"B", 2=>"C", 3=>"D")

get_edge_attribute(sub, :weight)
# Dict((1,2)=>2.0, (2,3)=>3.0)
```

Network-level attributes are also copied to the subgraph.

### Vertex Permutation

When permuting vertices, attributes follow the vertices:

```julia
net = Network(3)
add_edges!(net, [(1,2), (2,3)])
set_vertex_attribute!(net, :name, Dict(1=>"A", 2=>"B", 3=>"C"))

net_perm = permute_vertices(net, [3, 1, 2])
# Old vertex 3 is now vertex 1, old 1 is now 2, old 2 is now 3

get_vertex_attribute(net_perm, :name)
# Dict(1=>"C", 2=>"A", 3=>"B")
```

### Edge Removal

When an edge is removed, its attributes are automatically deleted:

```julia
net = Network(3)
add_edge!(net, 1, 2)
set_edge_attribute!(net, :weight, 1, 2, 5.0)

rem_edge!(net, 1, 2)
get_edge_attribute(net, :weight, 1, 2)  # nothing
```

### Vertex Removal

When a vertex is removed, all its attributes and the attributes of incident edges are deleted:

```julia
net = Network(3)
add_edge!(net, 1, 2)
add_edge!(net, 2, 3)
set_vertex_attribute!(net, :name, Dict(1=>"A", 2=>"B", 3=>"C"))

rem_vertex!(net, 2)
# Vertex 2 and edges (1,2), (2,3) are all removed
# Vertex 3 is renumbered to 2
```

## Attribute Data Types

Attribute values can be any Julia type:

```julia
# Strings
set_vertex_attribute!(net, :name, 1, "Alice")

# Numbers
set_vertex_attribute!(net, :age, 1, 30)
set_edge_attribute!(net, :weight, 1, 2, 3.14)

# Symbols
set_edge_attribute!(net, :type, 1, 2, :friendship)

# Vectors
set_vertex_attribute!(net, :coordinates, 1, [40.7128, -74.0060])

# Dicts
set_network_attribute!(net, :metadata, Dict("year" => 2024, "complete" => true))

# Custom types
struct Location
    lat::Float64
    lon::Float64
end
set_vertex_attribute!(net, :location, 1, Location(40.7128, -74.0060))
```

Since attribute storage uses `Dict{..., Any}`, any Julia object can be stored. However, for serialization (writing to files), stick to basic types (strings, numbers, symbols).

## Best Practices

1. **Use meaningful attribute names**: Choose descriptive Symbol names like `:department`, `:friendship_strength`, `:year_established`.

2. **Be consistent with types**: All values for a given attribute should ideally have the same type (all strings, all numbers, etc.) to avoid surprises when processing.

3. **Document your attributes**: Use network-level attributes to store a description of each vertex/edge attribute:
   ```julia
   set_network_attribute!(net, :attribute_descriptions,
       Dict(:weight => "Interaction frequency per month",
            :type => "Relationship category"))
   ```

4. **Check attribute existence**: Use `list_vertex_attributes` before assuming an attribute exists.

5. **Use bracket syntax for quick access**: The `net[:v, :attr]` syntax is concise for interactive use.

6. **Prefer bulk operations**: When setting attributes for many vertices/edges, use the Dict or Vector form of `set_vertex_attribute!` rather than looping over individual calls.
