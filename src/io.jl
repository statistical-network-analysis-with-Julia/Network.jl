# I/O functions for Network objects.
#
# Provides functions to read and write networks in various formats,
# including Pajek format commonly used in network analysis.

# ============================================================================
# Pajek Format
# ============================================================================

"""
    read_pajek(filepath::String) -> Network

Read a network from a Pajek (.net) file.

# Pajek Format
```
*Vertices n
1 "vertex1"
2 "vertex2"
...
*Edges (or *Arcs for directed)
1 2 weight
2 3 weight
...
```
"""
function read_pajek(filepath::String)
    lines = readlines(filepath)

    n = 0
    directed = false
    edges = Tuple{Int, Int, Float64}[]
    vertex_names = Dict{Int, String}()

    mode = :none
    for line in lines
        line = strip(line)
        isempty(line) && continue
        startswith(line, "%") && continue  # Comment

        lower_line = lowercase(line)

        if startswith(lower_line, "*vertices")
            mode = :vertices
            # Parse number of vertices
            parts = split(line)
            if length(parts) >= 2
                n = parse(Int, parts[2])
            end
        elseif startswith(lower_line, "*arcs")
            mode = :arcs
            directed = true
        elseif startswith(lower_line, "*edges")
            mode = :edges
            directed = false
        elseif mode == :vertices
            # Parse vertex line: id "label" or just id
            parts = split(line)
            if !isempty(parts)
                id = parse(Int, parts[1])
                if length(parts) >= 2
                    # Extract label (may be quoted)
                    label = join(parts[2:end], " ")
                    label = strip(label, ['"', '\''])
                    vertex_names[id] = label
                end
            end
        elseif mode in (:arcs, :edges)
            # Parse edge line: source target [weight]
            parts = split(line)
            if length(parts) >= 2
                src = parse(Int, parts[1])
                dst = parse(Int, parts[2])
                weight = length(parts) >= 3 ? parse(Float64, parts[3]) : 1.0
                push!(edges, (src, dst, weight))
            end
        end
    end

    # Create network
    net = Network(n; directed=directed)

    # Add vertex names
    if !isempty(vertex_names)
        set_vertex_attribute!(net, :vertex_names, vertex_names)
    end

    # Add edges
    has_weights = any(e[3] != 1.0 for e in edges)
    for (src, dst, weight) in edges
        add_edge!(net, src, dst)
        if has_weights
            set_edge_attribute!(net, :weight, src, dst, weight)
        end
    end

    return net
end

"""
    write_pajek(net::Network, filepath::String; vertex_names::Symbol=:vertex_names,
                edge_weight::Symbol=:weight)

Write a network to a Pajek (.net) file.

# Arguments
- `net::Network`: The network to write
- `filepath::String`: Output file path
- `vertex_names::Symbol`: Vertex attribute to use as labels
- `edge_weight::Symbol`: Edge attribute to use as weights
"""
function write_pajek(net::Network, filepath::String;
                     vertex_names::Symbol=:vertex_names,
                     edge_weight::Symbol=:weight)
    open(filepath, "w") do io
        n = nv(net)

        # Write vertices
        println(io, "*Vertices $n")
        names = get_vertex_attribute(net, vertex_names)
        for v in 1:n
            if haskey(names, v)
                println(io, "$v \"$(names[v])\"")
            else
                println(io, v)
            end
        end

        # Write edges
        if net.directed
            println(io, "*Arcs")
        else
            println(io, "*Edges")
        end

        weights = get_edge_attribute(net, edge_weight)
        for e in edges(net)
            i, j = src(e), dst(e)
            edge = _canonical_edge(net, i, j)
            if haskey(weights, edge)
                println(io, "$i $j $(weights[edge])")
            else
                println(io, "$i $j")
            end
        end
    end
end

# ============================================================================
# GraphML Format (basic support)
# ============================================================================

"""
    write_graphml(net::Network, filepath::String)

Write a network to GraphML format (basic implementation).
"""
function write_graphml(net::Network, filepath::String)
    open(filepath, "w") do io
        println(io, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        println(io, "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">")

        # Define attribute keys
        for attr in list_vertex_attributes(net)
            println(io, "  <key id=\"v_$attr\" for=\"node\" attr.name=\"$attr\" attr.type=\"string\"/>")
        end
        for attr in list_edge_attributes(net)
            println(io, "  <key id=\"e_$attr\" for=\"edge\" attr.name=\"$attr\" attr.type=\"string\"/>")
        end

        # Graph element
        edgedefault = net.directed ? "directed" : "undirected"
        println(io, "  <graph id=\"G\" edgedefault=\"$edgedefault\">")

        # Vertices
        for v in vertices(net)
            println(io, "    <node id=\"n$v\">")
            for attr in list_vertex_attributes(net)
                val = get_vertex_attribute(net, attr, v)
                if !isnothing(val)
                    println(io, "      <data key=\"v_$attr\">$val</data>")
                end
            end
            println(io, "    </node>")
        end

        # Edges
        edge_id = 0
        for e in edges(net)
            i, j = src(e), dst(e)
            println(io, "    <edge id=\"e$edge_id\" source=\"n$i\" target=\"n$j\">")
            for attr in list_edge_attributes(net)
                val = get_edge_attribute(net, attr, i, j)
                if !isnothing(val)
                    println(io, "      <data key=\"e_$attr\">$val</data>")
                end
            end
            println(io, "    </edge>")
            edge_id += 1
        end

        println(io, "  </graph>")
        println(io, "</graphml>")
    end
end

# ============================================================================
# Edge List CSV
# ============================================================================

"""
    write_edgelist_csv(net::Network, filepath::String; attrs::Vector{Symbol}=Symbol[])

Write network as a CSV edge list.
"""
function write_edgelist_csv(net::Network, filepath::String; attrs::Vector{Symbol}=Symbol[])
    df = as_dataframe(net; vertices=false, attrs=attrs)
    # Would use CSV.write here, but to avoid adding CSV dependency:
    open(filepath, "w") do io
        # Header
        println(io, join(names(df), ","))
        # Data
        for row in eachrow(df)
            values = [ismissing(v) ? "" : string(v) for v in row]
            println(io, join(values, ","))
        end
    end
end
