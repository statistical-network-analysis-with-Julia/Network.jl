# Graph Interface API Reference

This page documents the Graphs.jl `AbstractGraph` interface methods implemented by Network.jl. These functions allow `Network` objects to work seamlessly with the entire Graphs.jl algorithm library.

## Basic Properties

### nv

```@docs
nv
```

### ne

```@docs
ne
```

### vertices

```@docs
vertices
```

### edges

```@docs
edges
```

### has\_vertex

```@docs
has_vertex
```

### has\_edge

```@docs
has_edge
```

### is\_directed

```@docs
is_directed
```

### is\_bipartite

```@docs
is_bipartite
```

## Vertex Modification

### add\_vertex!

```@docs
add_vertex!
```

### add\_vertices!

```@docs
add_vertices!
```

### rem\_vertex!

```@docs
rem_vertex!
```

## Edge Modification

### add\_edge!

```@docs
add_edge!
```

### add\_edges!

```@docs
add_edges!
```

### rem\_edge!

```@docs
rem_edge!
```

## Neighbors

### neighbors

```@docs
neighbors
```

### inneighbors

```@docs
inneighbors
```

### outneighbors

```@docs
outneighbors
```

## Utility Functions

### network\_size

```@docs
network_size
```

### network\_edgecount

```@docs
network_edgecount
```

### network\_density

```@docs
network_density
```

### get\_neighborhood

```@docs
get_neighborhood
```

### get\_induced\_subgraph

```@docs
get_induced_subgraph
```

### permute\_vertices

```@docs
permute_vertices
```
