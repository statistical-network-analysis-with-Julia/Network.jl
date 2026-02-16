using Documenter
using Network

DocMeta.setdocmeta!(Network, :DocTestSetup, :(using Network); recursive=true)

makedocs(
    sitename = "Network.jl",
    modules = [Network],
    authors = "Statistical Network Analysis with Julia",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://Statistical-network-analysis-with-Julia.github.io/Network.jl",
        edit_link = "main",
    ),
    repo = "https://github.com/Statistical-network-analysis-with-Julia/Network.jl/blob/{commit}{path}#{line}",
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "User Guide" => [
            "Creating Networks" => "guide/construction.md",
            "Attributes" => "guide/attributes.md",
            "Conversion" => "guide/conversion.md",
            "I/O" => "guide/io.md",
        ],
        "API Reference" => [
            "Types" => "api/types.md",
            "Graph Interface" => "api/graph_interface.md",
            "Attributes" => "api/attributes.md",
            "Conversion & I/O" => "api/conversion.md",
        ],
    ],
    warnonly = [:missing_docs, :docs_block],
)

deploydocs(
    repo = "github.com/Statistical-network-analysis-with-Julia/Network.jl.git",
    devbranch = "main",
    versions = [
        "stable" => "dev", # serve dev docs at /stable until a release is tagged
        "dev" => "dev",
    ],
    push_preview = true,
)
