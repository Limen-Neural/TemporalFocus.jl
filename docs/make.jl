using Documenter, TemporalFocus
makedocs(
    sitename = "TemporalFocus.jl",
    modules = [TemporalFocus],
    checkdocs = :none,  # tighten to :exports after #17 docstrings merge
    format = Documenter.HTML(prettyurls = get(ENV, "CI", "false") == "true"),
    pages = ["Home" => "index.md", "API" => "api.md"],
)
deploydocs(repo = "github.com/Limen-Neural/TemporalFocus.jl.git", push_preview = true)
