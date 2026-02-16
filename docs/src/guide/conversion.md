# Conversion

Network.jl provides functions to convert networks to and from adjacency matrices, edge lists, and DataFrames. These conversions mirror R's `as.matrix.network`, `as.edgelist`, and related functions from the `network` package.

## Network to Matrix

### Binary Adjacency Matrix

Convert a network to its adjacency matrix representation where 1 indicates an edge and 0 indicates no edge:

```julia
using Network

net = Network(4)
add_edges!(net, [(1,2), (2,3), (3,4), (4,1)])

A = as_matrix(net)
# 4x4 Matrix{Float64}:
#  0.0  1.0  0.0  0.0
#  0.0  0.0  1.0  0.0
#  0.0  0.0  0.0  1.0
#  1.0  0.0  0.0  0.0
```

For undirected networks, the matrix is symmetric:

```julia
net = Network(4; directed=false)
add_edges!(net, [(1,2), (2,3), (3,4)])

A = as_matrix(net)
# 4x4 Matrix{Float64}:
#  0.0  1.0  0.0  0.0
#  1.0  0.0  1.0  0.0
#  0.0  1.0  0.0  1.0
#  0.0  0.0  1.0  0.0
```

### Weighted Adjacency Matrix

Use an edge attribute as cell values:

```julia
net = Network(4)
add_edges!(net, [(1,2), (2,3), (3,4), (4,1)])
set_edge_attribute!(net, :weight,
    Dict((1,2) => 1.0, (2,3) => 2.5, (3,4) => 0.8, (4,1) => 1.2))

W = as_matrix(net; attr=:weight)
# 4x4 Matrix{Float64}:
#  0.0  1.0  0.0  0.0
#  0.0  0.0  2.5  0.0
#  0.0  0.0  0.0  0.8
#  1.2  0.0  0.0  0.0
```

Edges without the specified attribute are treated as 0.0.

### Sparse Adjacency Matrix

For large networks, use sparse matrices to save memory:

```julia
S = as_matrix(net; sparse=true)
# 4x4 SparseMatrixCSC{Float64, Int64} with 4 stored entries:
#  ...

# Sparse weighted matrix
S = as_matrix(net; attr=:weight, sparse=true)
```

Sparse matrices are recommended for networks with more than a few hundred vertices, especially when the network is sparse (low density).

### Alias: as_adjacency_matrix

`as_adjacency_matrix` is an alias for `as_matrix`, matching R's `as.matrix.network` with `matrix.type="adjacency"`:

```julia
A = as_adjacency_matrix(net)  # equivalent to as_matrix(net)
```

### Function Signature

```julia
as_matrix(net::Network;
    attr::Union{Symbol,Nothing} = nothing,  # Edge attribute for values (nothing=binary)
    sparse::Bool = false                     # Return SparseMatrixCSC if true
) -> Matrix{Float64} or SparseMatrixCSC{Float64}
```

## Network to Edge List

### Basic Edge List

Convert a network to an `n_edges x 2` matrix of source-target pairs:

```julia
net = Network(4)
add_edges!(net, [(1,2), (2,3), (3,4), (4,1)])

el = as_edgelist(net)
# 4x2 Matrix{Int64}:
#  1  2
#  2  3
#  3  4
#  4  1
```

### Edge List with Attributes

Request edge attribute values alongside the edge list:

```julia
set_edge_attribute!(net, :weight,
    Dict((1,2) => 1.0, (2,3) => 2.5, (3,4) => 0.8, (4,1) => 1.2))
set_edge_attribute!(net, :type,
    Dict((1,2) => :friend, (2,3) => :colleague, (3,4) => :friend, (4,1) => :colleague))

el, attrs = as_edgelist(net; attrs=[:weight, :type])

# el is the edge list matrix
# attrs is a Dict mapping attribute names to vectors
# attrs[:weight] == [1.0, 2.5, 0.8, 1.2]
# attrs[:type] == [:friend, :colleague, :friend, :colleague]
```

Edges without a specified attribute will have `missing` in the returned vector.

### Function Signature

```julia
as_edgelist(net::Network;
    attrs::Vector{Symbol} = Symbol[]  # Edge attributes to include
) -> Matrix{Int} or Tuple{Matrix{Int}, Dict{Symbol, Vector}}
```

## Network to DataFrame

### Edge DataFrame

Convert the network's edges to a DataFrame:

```julia
using DataFrames

net = Network(4)
add_edges!(net, [(1,2), (2,3), (3,4)])
set_edge_attribute!(net, :weight, Dict((1,2)=>1.0, (2,3)=>2.5, (3,4)=>0.8))

edge_df = as_dataframe(net)
# 3x3 DataFrame
#  Row | source  target  weight
# -----+------------------------
#    1 |      1       2     1.0
#    2 |      2       3     2.5
#    3 |      3       4     0.8
```

By default, all edge attributes are included. To select specific attributes:

```julia
edge_df = as_dataframe(net; attrs=[:weight])
```

### Vertex DataFrame

Convert vertex attributes to a DataFrame:

```julia
set_vertex_attribute!(net, :name, Dict(1=>"A", 2=>"B", 3=>"C", 4=>"D"))
set_vertex_attribute!(net, :age, [25, 30, 28, 35])

vertex_df = as_dataframe(net; vertices=true)
# 4x3 DataFrame
#  Row | vertex  name    age
# -----+---------------------
#    1 |      1  A        25
#    2 |      2  B        30
#    3 |      3  C        28
#    4 |      4  D        35
```

Vertices without a value for an attribute will have `missing` in the DataFrame.

### Function Signature

```julia
as_dataframe(net::Network;
    vertices::Bool = false,             # If true, return vertex DataFrame
    attrs::Vector{Symbol} = Symbol[]    # Attributes to include (empty = all)
) -> DataFrame
```

## Matrix to Network

### From a Binary Matrix

Create a network from a 0/1 adjacency matrix:

```julia
A = [0 1 1 0;
     0 0 1 0;
     0 0 0 1;
     1 0 0 0]

net = network_from_matrix(A)
nv(net)  # 4
ne(net)  # 5 (all the 1s in A)
```

### From a Weighted Matrix

Non-binary matrices are automatically detected. Edge weights are stored as an attribute:

```julia
W = [0.0  1.5  0.0;
     2.0  0.0  3.0;
     0.0  0.0  0.0]

net = network_from_matrix(W)
nv(net)  # 3
ne(net)  # 3

# Weights are stored as the :weight attribute by default
get_edge_attribute(net, :weight, 1, 2)  # 1.5
get_edge_attribute(net, :weight, 2, 1)  # 2.0
```

### Undirected Networks from Matrices

For undirected networks, only the upper triangle is used:

```julia
A = [0 1 0 1;
     1 0 1 0;
     0 1 0 1;
     1 0 1 0]

net = network_from_matrix(A; directed=false)
ne(net)  # 4 (not 8)
```

### Custom Ignore Values

By default, zeros are treated as "no edge". Use `ignore_eval` to customize:

```julia
# Treat -1 as "no edge" instead of 0
M = [-1  1  2;
      3 -1  4;
      5  6 -1]

net = network_from_matrix(M; ignore_eval=(x -> x == -1))
ne(net)  # 6
```

### Vertex Names

Optionally assign vertex names:

```julia
A = [0 1; 1 0]
names = Dict(1 => "Alice", 2 => "Bob")

net = network_from_matrix(A; names_eval=names)
get_vertex_attribute(net, :vertex_names)
# Dict(1 => "Alice", 2 => "Bob")
```

### Custom Weight Attribute Name

```julia
net = network_from_matrix(W; attr=:strength)
get_edge_attribute(net, :strength, 1, 2)  # 1.5
```

### Function Signature

```julia
network_from_matrix(A::AbstractMatrix;
    directed::Bool = true,
    loops::Bool = false,
    ignore_eval = nothing,       # Function: value → Bool (true = ignore)
    names_eval = nothing,        # Dict{Int,String} or Vector{String}
    attr::Symbol = :weight       # Attribute name for non-binary values
) -> Network
```

## Edge List to Network

### From Tuples

```julia
edges = [(1, 2), (2, 3), (3, 4), (4, 1)]
net = network_from_edgelist(edges)
nv(net)  # 4
ne(net)  # 4
```

### From a Matrix

```julia
el = [1 2; 2 3; 3 4; 4 1]
net = network_from_edgelist(el)
```

### Specifying Number of Vertices

By default, the number of vertices is auto-detected as the maximum vertex ID. To add isolated vertices:

```julia
edges = [(1, 2), (2, 3)]
net = network_from_edgelist(edges; n=10)  # 10 vertices, not 3
nv(net)  # 10
ne(net)  # 2
```

### Undirected Edge Lists

```julia
edges = [(1, 2), (2, 3), (3, 1)]
net = network_from_edgelist(edges; directed=false)
has_edge(net, 2, 1)  # true  -- symmetric
```

### Function Signature

```julia
network_from_edgelist(edges;
    n::Union{Int,Nothing} = nothing,  # Number of vertices (auto-detect if nothing)
    directed::Bool = true,
    loops::Bool = false
) -> Network
```

## DataFrame to Network

### Basic Usage

Create a network from a DataFrame with source and target columns:

```julia
using DataFrames

df = DataFrame(
    source = [1, 1, 2, 3],
    target = [2, 3, 3, 4],
    weight = [1.0, 2.0, 1.5, 3.0],
    type = ["friend", "colleague", "friend", "mentor"]
)

net = network_from_dataframe(df)
nv(net)  # 4
ne(net)  # 4

# Additional columns are stored as edge attributes
get_edge_attribute(net, :weight, 1, 2)  # 1.0
get_edge_attribute(net, :type, 1, 3)    # "colleague"
```

### Custom Column Names

```julia
df = DataFrame(
    from = [1, 2, 3],
    to = [2, 3, 1],
    strength = [5.0, 3.0, 4.0]
)

net = network_from_dataframe(df; source=:from, target=:to)
# :strength is automatically stored as an edge attribute
```

### Undirected from DataFrame

```julia
df = DataFrame(source=[1,2,3], target=[2,3,1])
net = network_from_dataframe(df; directed=false)
```

### Function Signature

```julia
network_from_dataframe(df::DataFrame;
    source::Symbol = :source,    # Column name for source vertices
    target::Symbol = :target,    # Column name for target vertices
    directed::Bool = true,
    loops::Bool = false
) -> Network
```

## Round-Trip Conversions

### Network → Matrix → Network

```julia
# Start with a network
net1 = Network(4)
add_edges!(net1, [(1,2), (2,3), (3,4)])
set_edge_attribute!(net1, :weight,
    Dict((1,2)=>1.5, (2,3)=>2.0, (3,4)=>0.8))

# Convert to weighted matrix
W = as_matrix(net1; attr=:weight)

# Convert back
net2 = network_from_matrix(W)
ne(net2)  # 3
get_edge_attribute(net2, :weight, 1, 2)  # 1.5
```

### Network → DataFrame → Network

```julia
# Start with a network
net1 = Network(3)
add_edges!(net1, [(1,2), (2,3)])
set_edge_attribute!(net1, :weight, Dict((1,2)=>1.0, (2,3)=>2.0))

# Convert to DataFrame
df = as_dataframe(net1)

# Convert back
net2 = network_from_dataframe(df)
ne(net2)  # 2
get_edge_attribute(net2, :weight, 2, 3)  # 2.0
```

### Network → Edge List → Network

```julia
net1 = Network(5)
add_edges!(net1, [(1,2), (2,3), (3,4), (4,5)])

el = as_edgelist(net1)
net2 = network_from_edgelist(el; n=5)
ne(net2)  # 4
```

!!! note "Attribute Preservation"
    Round-trip conversions through matrices preserve only the edge structure (and a single weight attribute). For full attribute preservation, use DataFrame conversions which preserve all edge attributes. Vertex and network attributes are not preserved in any round-trip conversion -- save them separately if needed.

## Working with Graphs.jl

Since `Network` implements `AbstractGraph`, Graphs.jl functions that accept matrices work with Network's matrix output:

```julia
using Graphs
using LinearAlgebra

net = Network(5; directed=false)
add_edges!(net, [(1,2), (2,3), (3,4), (4,5), (1,5)])

# Get adjacency matrix
A = as_matrix(net)

# Compute eigenvalues (spectrum)
eigenvalues = eigvals(Symmetric(A))

# Compute Laplacian
D = Diagonal(vec(sum(A, dims=2)))
L = D - A
```

## Sparse Matrix Integration

For integration with sparse linear algebra:

```julia
using SparseArrays

net = Network(1000)
# ... add edges ...

# Get sparse adjacency matrix
S = as_matrix(net; sparse=true)

# Use with sparse linear algebra
using Arpack
eigenvalues, eigenvectors = eigs(S; nev=5, which=:LM)
```

## Best Practices

1. **Use sparse matrices for large networks**: Dense `n x n` matrices consume `O(n^2)` memory. Sparse matrices store only non-zero entries.

2. **Choose the right format**: Use matrices for linear algebra, DataFrames for data manipulation, edge lists for simple enumeration.

3. **Be aware of attribute loss**: Matrix conversion only preserves one edge attribute (as weights). Use DataFrame conversion to preserve all edge attributes.

4. **Check directedness**: Matrix conversion for undirected networks produces symmetric matrices. Ensure the `directed` flag is set correctly when converting back.

5. **Handle isolated vertices**: When converting from edge lists, specify `n` explicitly if the network has isolated vertices (no edges), otherwise they will be dropped.
