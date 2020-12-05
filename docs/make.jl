using Documenter, Minesweeper

makedocs(
    sitename = "Minesweeper.jl",
    modules  = [Minesweeper],
    doctest  = false,
    pages    = [
        "API.md",
        "create_game.md",
        "play_without_gui.md",
        "play_with_gui.md",
        "run_simulation.md",
    ]
)


deploydocs(
    repo = "https://github.com/itsdfish/Minesweeper.jl.git",
    versions = ["stable" => "v^", "v#.#", "dev" => "master"]
)