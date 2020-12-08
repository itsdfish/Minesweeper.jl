module Minesweeper
    using StatsBase
    import Base: show
    export Game, Cell, add_mines!, get_neighbors, reveal_zeros!, game_over
    export get_neighbor_indices, show, reveal, play, compute_score!
    export update!, select_cell!, initilize_cells, mine_count!, import_gui
    export flag_button!, update_flag_count!
    export generate_gui, reveal_button!
    include("Game.jl")
end
