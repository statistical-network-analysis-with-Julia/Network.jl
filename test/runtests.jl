using Network
using Test
using Graphs

@testset "Network.jl" begin
    @testset "Network Construction" begin
        # Basic construction
        net = network(5)
        @test nv(net) == 5
        @test ne(net) == 0
        @test is_directed(net) == true

        # Undirected network
        net_undir = network(5; directed=false)
        @test is_directed(net_undir) == false

        # Using network() function
        net2 = network(10; directed=false)
        @test nv(net2) == 10
        @test is_directed(net2) == false

        # network_initialize alias
        net3 = network_initialize(3)
        @test nv(net3) == 3
    end

    @testset "Edge Operations" begin
        net = network(5)

        # Add edges
        @test add_edge!(net, 1, 2) == true
        @test add_edge!(net, 2, 3) == true
        @test add_edge!(net, 3, 4) == true

        @test ne(net) == 3
        @test has_edge(net, 1, 2) == true
        @test has_edge(net, 2, 1) == false  # Directed

        # Remove edge
        @test rem_edge!(net, 1, 2) == true
        @test has_edge(net, 1, 2) == false
        @test ne(net) == 2

        # Self-loops (not allowed by default)
        @test add_edge!(net, 1, 1) == false

        # Self-loops (when allowed)
        net_loops = network(3; loops=true)
        @test add_edge!(net_loops, 1, 1) == true
        @test has_edge(net_loops, 1, 1) == true
    end

    @testset "Undirected Edge Operations" begin
        net = network(5; directed=false)

        add_edge!(net, 1, 2)
        add_edge!(net, 2, 3)

        # Both directions should work
        @test has_edge(net, 1, 2) == true
        @test has_edge(net, 2, 1) == true

        # Edge count should be 2 (not 4)
        @test ne(net) == 2
    end

    @testset "Vertex Attributes" begin
        net = network(3)

        # Set via Dict
        set_vertex_attribute!(net, :name, Dict(1 => "Alice", 2 => "Bob", 3 => "Carol"))

        @test get_vertex_attribute(net, :name, 1) == "Alice"
        @test get_vertex_attribute(net, :name, 2) == "Bob"

        # Set via Vector
        set_vertex_attribute!(net, :age, [25, 30, 35])
        @test get_vertex_attribute(net, :age, 1) == 25
        @test get_vertex_attribute(net, :age, 3) == 35

        # Set single vertex
        set_vertex_attribute!(net, :score, 1, 100.0)
        @test get_vertex_attribute(net, :score, 1) == 100.0

        # List attributes
        @test :name in list_vertex_attributes(net)
        @test :age in list_vertex_attributes(net)

        # Delete attribute
        delete_vertex_attribute!(net, :score)
        @test !(:score in list_vertex_attributes(net))
    end

    @testset "Edge Attributes" begin
        net = network(3)
        add_edge!(net, 1, 2)
        add_edge!(net, 2, 3)

        # Set via Dict
        set_edge_attribute!(net, :weight, Dict((1,2) => 1.5, (2,3) => 2.0))

        @test get_edge_attribute(net, :weight, 1, 2) == 1.5
        @test get_edge_attribute(net, :weight, 2, 3) == 2.0

        # Set single edge
        set_edge_attribute!(net, :label, 1, 2, "friendship")
        @test get_edge_attribute(net, :label, 1, 2) == "friendship"

        # List attributes
        @test :weight in list_edge_attributes(net)
    end

    @testset "Network Attributes" begin
        net = network(3)

        set_network_attribute!(net, :title, "Test Network")
        set_network_attribute!(net, :year, 2024)

        @test get_network_attribute(net, :title) == "Test Network"
        @test get_network_attribute(net, :year) == 2024

        @test :title in list_network_attributes(net)

        delete_network_attribute!(net, :year)
        @test isnothing(get_network_attribute(net, :year))
    end

    @testset "Neighbors" begin
        net = network(5)
        add_edge!(net, 1, 2)
        add_edge!(net, 1, 3)
        add_edge!(net, 4, 1)

        @test Set(outneighbors(net, 1)) == Set([2, 3])
        @test Set(inneighbors(net, 1)) == Set([4])
        @test Set(neighbors(net, 1)) == Set([2, 3])  # outneighbors for directed
    end

    @testset "Matrix Conversion" begin
        net = network(3)
        add_edge!(net, 1, 2)
        add_edge!(net, 2, 3)
        add_edge!(net, 3, 1)

        A = as_matrix(net)
        @test size(A) == (3, 3)
        @test A[1, 2] == 1.0
        @test A[2, 3] == 1.0
        @test A[3, 1] == 1.0
        @test A[1, 1] == 0.0

        # Weighted matrix
        set_edge_attribute!(net, :weight, Dict((1,2) => 0.5, (2,3) => 1.0, (3,1) => 0.75))
        W = as_matrix(net; attr=:weight)
        @test W[1, 2] == 0.5
        @test W[2, 3] == 1.0
    end

    @testset "Edge List Conversion" begin
        net = network(3)
        add_edge!(net, 1, 2)
        add_edge!(net, 2, 3)

        el = as_edgelist(net)
        @test size(el) == (2, 2)
        @test (1, 2) in [(el[i, 1], el[i, 2]) for i in 1:2]
        @test (2, 3) in [(el[i, 1], el[i, 2]) for i in 1:2]
    end

    @testset "Network from Matrix" begin
        A = [0 1 0; 0 0 1; 1 0 0]
        net = network_from_matrix(A)

        @test nv(net) == 3
        @test ne(net) == 3
        @test has_edge(net, 1, 2)
        @test has_edge(net, 2, 3)
        @test has_edge(net, 3, 1)

        # Undirected from symmetric matrix
        B = [0 1 1; 1 0 0; 1 0 0]
        net_undir = network_from_matrix(B; directed=false)
        @test ne(net_undir) == 2  # (1,2) and (1,3)
    end

    @testset "Network from Edge List" begin
        edges = [(1, 2), (2, 3), (3, 1)]
        net = network_from_edgelist(edges)

        @test nv(net) == 3
        @test ne(net) == 3
        @test has_edge(net, 1, 2)
        @test has_edge(net, 2, 3)
        @test has_edge(net, 3, 1)
    end

    @testset "Network Density" begin
        # Complete directed graph
        net = network(3)
        add_edge!(net, 1, 2)
        add_edge!(net, 1, 3)
        add_edge!(net, 2, 1)
        add_edge!(net, 2, 3)
        add_edge!(net, 3, 1)
        add_edge!(net, 3, 2)

        @test network_density(net) == 1.0  # 6 edges / 6 possible

        # Partial network
        net2 = network(3)
        add_edge!(net2, 1, 2)
        add_edge!(net2, 2, 3)
        @test network_density(net2) ≈ 2/6
    end

    @testset "Induced Subgraph" begin
        net = network(5)
        add_edge!(net, 1, 2)
        add_edge!(net, 2, 3)
        add_edge!(net, 3, 4)
        add_edge!(net, 4, 5)

        set_vertex_attribute!(net, :name, Dict(1 => "A", 2 => "B", 3 => "C", 4 => "D", 5 => "E"))

        sub = get_induced_subgraph(net, [2, 3, 4])

        @test nv(sub) == 3
        @test ne(sub) == 2  # (2,3) and (3,4) mapped to (1,2) and (2,3)
        @test has_edge(sub, 1, 2)  # was 2→3
        @test has_edge(sub, 2, 3)  # was 3→4
    end

    @testset "Neighborhood" begin
        net = network(5)
        add_edge!(net, 1, 2)
        add_edge!(net, 2, 3)
        add_edge!(net, 3, 4)
        add_edge!(net, 4, 5)

        # Order 1 neighborhood
        n1 = get_neighborhood(net, 1, 1)
        @test 1 in n1
        @test 2 in n1
        @test !(3 in n1)

        # Order 2 neighborhood
        n2 = get_neighborhood(net, 1, 2)
        @test 1 in n2
        @test 2 in n2
        @test 3 in n2
        @test !(4 in n2)
    end

    @testset "Bipartite Network" begin
        bnet = BipartiteNetwork(3, 4)

        @test nv(bnet) == 7
        @test is_bipartite(bnet) == true
        @test bnet.n_mode1 == 3
        @test bnet.n_mode2 == 4
    end

    @testset "Vertex Permutation" begin
        net = network(3)
        add_edge!(net, 1, 2)
        add_edge!(net, 2, 3)
        set_vertex_attribute!(net, :name, Dict(1 => "A", 2 => "B", 3 => "C"))

        # Permute: old 1 -> new 3, old 2 -> new 1, old 3 -> new 2
        perm = [2, 3, 1]  # new position i has old vertex perm[i]
        net_perm = permute_vertices(net, perm)

        @test nv(net_perm) == 3
        @test ne(net_perm) == 2

        # Check vertex attributes were permuted correctly
        names = get_vertex_attribute(net_perm, :name)
        @test names[1] == "B"  # old vertex 2 is now vertex 1
        @test names[2] == "C"  # old vertex 3 is now vertex 2
        @test names[3] == "A"  # old vertex 1 is now vertex 3
    end
end
