using ContextualREPLHistory
using Documenter

DocMeta.setdocmeta!(ContextualREPLHistory, :DocTestSetup, :(using ContextualREPLHistory); recursive=true)

makedocs(;
    modules=[ContextualREPLHistory],
    authors="caleb-allen <caleb.e.allen@gmail.com> and contributors",
    repo="https://github.com/caleb-allen/ContextualREPLHistory.jl/blob/{commit}{path}#{line}",
    sitename="ContextualREPLHistory.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://caleb-allen.github.io/ContextualREPLHistory.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/caleb-allen/ContextualREPLHistory.jl",
    devbranch="main",
)
