# Creating Networks

This guide covers all aspects of creating, modifying, and inspecting networks in Network.jl.

## Network Constructors

### Basic Constructor

The primary way to create a network is with the `Network` constructor:

```julia
using Network

# Empty network (no vertices)
net = Network()

# Network with n vertices and no edges
net = Network(10)

# With type parameter
net = Network{Int64}(; n=10)
```

### R-Style Aliases

Network.jl provides aliases that match R's `network` package API:

```julia
# Equivalent to Network(10)
net = network(10)

# Equivalent to Network(10)
net = network_initialize(10)
```

### Constructor Options

All constructors accept keyword arguments controlling network properties:

```julia
net = Network(10;
    directed = true,         # Edge directionality
    bipartite = nothing,     # Set to Int for two-mode networks
    loops = false,           # Whether self-loops are allowed
    multiple = false,        # Whether multi-edges are allowed
    hyper = false,           # Whether hyperedges are allowed
)
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directed` | `Bool` | `true` | If true, edges have direction (source to target) |
| `bipartite` | `Union{Nothing,Int}` | `nothing` | Number of mode-1 vertices for bipartite networks |
| `loops` | `Bool` | `false` | Whether vertices can have edges to themselves |
| `multiple` | `Bool` | `false` | Whether parallel edges between the same pair are allowed |
| `hyper` | `Bool` | `false` | Whether edges can connect more than two vertices |

## Directed vs. Undirected Networks

The `directed` flag fundamentally affects how the network behaves:

### Directed Networks

In directed networks, each edge has a source (sender) and a target (receiver). Edge `(1, 2)` is distinct from edge `(2, 1)`:

```julia
net = Network(3; directed=true)
add_edge!(net, 1, 2)

has_edge(net, 1, 2)  # true
has_edge(net, 2, 1)  # false  -- direction matters
ne(net)              # 1
```

Directed networks are used for asymmetric relationships like email communication, citations, advice seeking, or Twitter follows.

### Undirected Networks

In undirected networks, edges are symmetric. Adding edge `(1, 2)` automatically creates `(2, 1)`:

```julia
net = Network(3; directed=false)
add_edge!(net, 1, 2)

has_edge(net, 1, 2)  # true
has_edge(net, 2, 1)  # true  -- both directions present
ne(net)              # 1     -- counted once, not twice
```

Undirected networks are used for symmetric relationships like friendship (in some contexts), co-authorship, physical proximity, or shared membership.

### Implementation Detail

Internally, Network.jl always stores edges in a `SimpleDiGraph`. For undirected networks, both `(i, j)` and `(j, i)` are stored, but `ne()` divides by 2 and `edges()` only returns edges where `src <= dst` to avoid double-counting. Edge attributes use a canonical ordering via `minmax(i, j)` to ensure consistent lookups regardless of which direction you specify.

## Adding and Removing Vertices

### Adding Vertices

```julia
net = Network(3)
nv(net)  # 3

# Add a single vertex
add_vertex!(net)
nv(net)  # 4

# Add multiple vertices
add_vertices!(net, 5)
nv(net)  # 9
```

New vertices are numbered sequentially starting after the current maximum vertex ID.

### Removing Vertices

```julia
net = Network(5)
add_edge!(net, 1, 2)
add_edge!(net, 2, 3)

# Remove vertex 2 (also removes edges incident to vertex 2)
rem_vertex!(net, 2)
nv(net)  # 4
```

When a vertex is removed:

1. All edges incident to that vertex are removed
2. All attributes for that vertex are deleted
3. Edge attributes for removed edges are deleted
4. The last vertex is renumbered to fill the gap (Graphs.jl convention)

!!! warning "Vertex Renumbering"
    When removing vertex `v`, vertex `nv(net)` is renumbered to `v`. This can invalidate vertex attribute mappings. Remove vertices with care, or remove in reverse order.

## Adding and Removing Edges

### Adding Single Edges

```julia
net = Network(5)

# Add an edge (returns true if successful, false if already exists)
add_edge!(net, 1, 2)   # true
add_edge!(net, 1, 2)   # false -- edge already exists

# Add an edge with attributes
add_edge!(net, 2, 3, Dict(:weight => 1.5, :type => :friendship))
```

### Self-Loops

By default, self-loops are not allowed:

```julia
net = Network(5; loops=false)
add_edge!(net, 1, 1)   # false -- self-loop rejected

net = Network(5; loops=true)
add_edge!(net, 1, 1)   # true -- self-loop allowed
```

### Adding Multiple Edges

```julia
net = Network(5)

# From a list of tuples
edges_to_add = [(1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
n_added = add_edges!(net, edges_to_add)  # returns 5
```

### Removing Edges

```julia
# Remove a single edge
rem_edge!(net, 1, 2)   # true if removed, false if not found

# For undirected networks, rem_edge! removes both directions
net = Network(3; directed=false)
add_edge!(net, 1, 2)
rem_edge!(net, 1, 2)
has_edge(net, 2, 1)     # false -- both directions removed
```

When an edge is removed, all its attributes are also deleted.

## Bipartite Networks

Bipartite (two-mode) networks have two distinct vertex sets where edges only connect vertices from different sets.

### Creating Bipartite Networks

```julia
# 4 actors x 3 events
bnet = BipartiteNetwork(4, 3)

# Vertices 1-4 are mode 1 (actors)
# Vertices 5-7 are mode 2 (events)
bnet.n_mode1  # 4
bnet.n_mode2  # 3
nv(bnet)      # 7
```

### Adding Edges

Edges should connect vertices from different modes:

```julia
add_edge!(bnet, 1, 5)   # Actor 1 -- Event 5
add_edge!(bnet, 1, 6)   # Actor 1 -- Event 6
add_edge!(bnet, 2, 5)   # Actor 2 -- Event 5
add_edge!(bnet, 3, 7)   # Actor 3 -- Event 7
add_edge!(bnet, 4, 6)   # Actor 4 -- Event 6
add_edge!(bnet, 4, 7)   # Actor 4 -- Event 7
```

### Checking Bipartiteness

```julia
is_bipartite(bnet)  # true

# Regular networks
net = Network(5)
is_bipartite(net)   # false

# You can also mark a Network as bipartite via the constructor
net = Network(7; bipartite=4)  # 4 vertices in mode 1
is_bipartite(net)   # true
```

### BipartiteNetwork Properties

```julia
println(bnet)
# BipartiteNetwork{Int64}:
#   Mode 1 vertices: 4
#   Mode 2 vertices: 3
#   Edges: 6
```

## Network Properties

### Size and Density

```julia
net = Network(10)
add_edges!(net, [(1,2), (2,3), (3,4), (4,5), (1,5)])

nv(net)                 # 10 -- number of vertices
ne(net)                 # 5  -- number of edges
network_size(net)       # 10 -- alias for nv()
network_edgecount(net)  # 5  -- alias for ne()
network_density(net)    # 0.0556 -- 5 / (10*9) for directed
```

### Density Calculation

The density formula depends on network type:

| Network Type | Formula | Maximum Edges |
|-------------|---------|---------------|
| Directed, no loops | `m / (n * (n-1))` | `n * (n-1)` |
| Directed, with loops | `m / (n * n)` | `n^2` |
| Undirected, no loops | `m / (n * (n-1) / 2)` | `n * (n-1) / 2` |
| Undirected, with loops | `m / (n * (n+1) / 2)` | `n * (n+1) / 2` |

### Directedness

```julia
is_directed(net)    # true or false
is_bipartite(net)   # true or false
```

### Vertex and Edge Iteration

```julia
# Iterate vertices
for v in vertices(net)
    println("Vertex: ", v)
end

# Iterate edges
for e in edges(net)
    println(src(e), " → ", dst(e))
end

# Existence checks
has_vertex(net, 3)    # true if vertex 3 exists
has_edge(net, 1, 2)   # true if edge (1,2) exists
```

## Neighborhoods and Subgraphs

### Neighborhoods

Find all vertices within a given distance of a focal vertex:

```julia
net = Network(6; directed=false)
add_edges!(net, [(1,2), (2,3), (3,4), (4,5), (5,6)])

# Direct neighbors of vertex 1 (order=1, default)
nbhood1 = get_neighborhood(net, 1)
# Set{Int64} with 2 elements: {1, 2}

# 2-neighborhood (distance <= 2)
nbhood2 = get_neighborhood(net, 1, 2)
# Set{Int64} with 3 elements: {1, 2, 3}

# 3-neighborhood
nbhood3 = get_neighborhood(net, 1, 3)
# Set{Int64} with 4 elements: {1, 2, 3, 4}
```

The returned set always includes the focal vertex itself.

### Induced Subgraphs

Extract a subnetwork containing only specified vertices and edges between them:

```julia
net = Network(6)
add_edges!(net, [(1,2), (1,3), (2,3), (3,4), (4,5), (5,6)])
set_vertex_attribute!(net, :name,
    Dict(1=>"A", 2=>"B", 3=>"C", 4=>"D", 5=>"E", 6=>"F"))
set_edge_attribute!(net, :weight,
    Dict((1,2)=>1.0, (1,3)=>2.0, (2,3)=>1.5, (3,4)=>3.0, (4,5)=>2.0, (5,6)=>1.0))

# Extract subgraph with vertices {1, 2, 3}
sub = get_induced_subgraph(net, [1, 2, 3])
nv(sub)  # 3
ne(sub)  # 3 (edges 1→2, 1→3, 2→3)

# Vertex and edge attributes are preserved (with remapped IDs)
get_vertex_attribute(sub, :name)  # Dict(1=>"A", 2=>"B", 3=>"C")
```

Note that vertex IDs are remapped to `1:length(vlist)` in the subgraph. Attributes are carried over with the new IDs.

## Vertex Permutation

Reorder vertex IDs according to a permutation:

```julia
net = Network(4)
add_edges!(net, [(1,2), (2,3), (3,4)])
set_vertex_attribute!(net, :name, Dict(1=>"A", 2=>"B", 3=>"C", 4=>"D"))

# Reverse the vertex order
perm = [4, 3, 2, 1]
net_perm = permute_vertices(net, perm)

# Vertex 1 in the new network was vertex 4 in the old
get_vertex_attribute(net_perm, :name, 1)  # "D"
get_vertex_attribute(net_perm, :name, 4)  # "A"
```

The permutation vector `perm` specifies which old vertex occupies each new position: `perm[new_id] = old_id`.

## Display

Networks have a compact display:

```julia
net = Network(5)
add_edges!(net, [(1,2), (2,3)])
set_vertex_attribute!(net, :name, Dict(1=>"Alice", 2=>"Bob"))
set_edge_attribute!(net, :weight, Dict((1,2) => 1.5))
set_network_attribute!(net, :title, "Test")

println(net)
# Network{Int64}: directed network
#   Vertices: 5
#   Edges: 2
#   Vertex attributes: name
#   Edge attributes: weight
#   Network attributes: title
```

## Creating Networks from External Data

Networks can also be created from matrices, edge lists, DataFrames, and files. See:

- [Conversion](conversion.md) for `network_from_matrix`, `network_from_edgelist`, and `network_from_dataframe`
- [I/O](io.md) for `read_pajek` and other file formats

## Random Graph Generation

For random graph generation, use the companion [SNA.jl](https://github.com/Statistical-network-analysis-with-Julia/SNA.jl) package which provides `rgraph`, `rgnm`, and `rgnp` functions:

```julia
using SNA

# Erdos-Renyi G(n,p) random graph
net = rgnp(100, 0.05)

# G(n,m) random graph with exactly m edges
net = rgnm(100, 200)
```

Or use Graphs.jl's random graph generators and convert:

```julia
using Graphs

g = erdos_renyi(100, 0.05)
# Use g directly -- Network.jl is compatible via AbstractGraph
```
