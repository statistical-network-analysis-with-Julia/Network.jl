# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Network.jl is a Julia port of the R `network` package from the StatNet ecosystem. It provides a `Network{T}` type that implements the Graphs.jl `AbstractGraph` interface while adding vertex, edge, and network-level attribute storage.

## Development Commands

```bash
# Run tests
julia --project -e 'using Pkg; Pkg.test()'

# Load package in REPL
julia --project -e 'using Network'
```

## Architecture

**Core types** (`src/types.jl`):
- `AbstractNetwork{T} <: Graphs.AbstractGraph{T}` — abstract base type
- `Network{T}` — main mutable struct; wraps a `SimpleDiGraph{T}` internally (even for undirected networks, which store both edge directions and halve `ne()`)
- `BipartiteNetwork{T}` — wraps a `Network{T}` with mode counts; vertices `1:n_mode1` are mode 1, rest are mode 2
- `_canonical_edge(net, i, j)` — returns `(i,j)` for directed, `minmax(i,j)` for undirected; used everywhere for edge attribute keying

**Source file organization**:
- `types.jl` — struct definitions, constructors (`Network()`, `network()`, `network_initialize()`), display
- `graphs_interface.jl` — Graphs.jl `AbstractGraph` method implementations (nv, ne, edges, add_edge!, etc.) plus utilities (density, neighborhood, induced subgraph, permute)
- `attributes.jl` — get/set/delete/list for vertex, edge, and network attributes; also `Base.getindex`/`setindex!` overloads for `net[:v, :attr]` syntax
- `coercion.jl` — conversions: `as_matrix`, `as_edgelist`, `as_dataframe`, `network_from_matrix`, `network_from_edgelist`, `network_from_dataframe`
- `io.jl` — Pajek (.net) read/write, GraphML write, CSV edge list write

**Undirected network pattern**: Undirected networks use a `SimpleDiGraph` internally with edges stored in both directions. `ne()` divides by 2, `edges()` filters to `src <= dst`, and `has_edge()` checks both directions.

**Julia 1.12 workaround**: The module contains a `let` block in `Network.jl` that redirects `Base.Docs.doc!` calls from `Type{Network}` to the module, because the `Network` struct shadows the module name.

## Key Dependencies

- **Graphs.jl** — provides `AbstractGraph` interface, `SimpleDiGraph` as internal storage
- **DataFrames.jl** — used for `as_dataframe` and `network_from_dataframe` conversions
- **SparseArrays** — sparse matrix support in `as_matrix`

## Conventions

- Attribute names are `Symbol`s; vertex attrs stored as `Dict{Symbol, Dict{T, Any}}`, edge attrs as `Dict{Symbol, Dict{Tuple{T,T}, Any}}`
- Mutating functions end with `!` (Julia convention)
- Functions mirroring R's statnet API use snake_case with `network_` prefix (e.g., `network_density`, `network_initialize`, `network_from_matrix`)
- Constructor aliases: `Network(n)`, `network(n)`, and `network_initialize(n)` all create the same thing
- Networks default to `directed=true`, `loops=false`
- Tests use flat `@testset` blocks in a single `test/runtests.jl` file; no separate test files
- No docs/ directory currently exists
