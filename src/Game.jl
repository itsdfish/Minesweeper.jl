"""
    Cell(;has_mine=false, flagged=false, revealed=false, mine_count=0, idx=(0,0))

Cell represents the state of a cell in Minesweeper
- `has_mine`: true if cell contains a mine
- `flagged`: true if cell has been flagged as having a mine
- `revealed`: true if the cell has been revealed
- `mine_count`: number of mines in adjecent cells
- `idx`: Cartesian indices of cell
"""
mutable struct Cell
    has_mine::Bool
    flagged::Bool
    revealed::Bool
    mine_count::Int
    idx::CartesianIndex
end

function Cell(;has_mine=false, flagged=false, revealed=false, mine_count=0, idx=(0,0))
    coords = CartesianIndex(idx)
    return Cell(has_mine, flagged, revealed, mine_count, coords)
end

"""
    Game(;dims=(12,12), n_mines=40, mines_flagged=0, mine_detonated=false, trials=0)

Minesweeper game object

- `cells`: an array of cells
- `dims`: a Tuple indicating dimensions of cell array
- `n_mines`: number of mines in the game
- `mines_flagged`: number of mines flagged
- `mine_detonated`: indicates whether a mine has been detonated
- `score`: score for game, which includes hits, misses, false alarms and correct rejections
- `trials`: the number of trials or moves
"""
mutable struct Game{T}
    cells::Array{Cell,2}
    dims::Tuple{Int,Int}
    n_mines::Int
    mines_flagged::Int
    mine_detonated::Bool
    score::T
    trials::Int
end

function Game(;dims=(12,12), n_mines=40, mines_flagged=0,
    mine_detonated=false, trials=0)
    score = (hits=0.0,false_alarms=0.0,misses=0.0,correct_rejections=0.0)
    cells = initilize_cells(dims)
    add_mines!(cells, n_mines)
    mine_count!(cells)
    return Game(cells, dims, n_mines, mines_flagged, mine_detonated,
        score, trials)
end

function initilize_cells(dims)
    return [Cell(idx=(r,c)) for r in 1:dims[1], c in 1:dims[2]]
end

function add_mines!(cells, n_mines)
    mines = sample(cells, n_mines, replace=false)
    for m in mines
        m.has_mine = true
    end
    return nothing
end

"""
    mine_count!(cells)

For each cell, omputes the number of neighboring cells containing a mine.
"""
function mine_count!(cells)
    for cell in cells
        neighbors = get_neighbors(cells, cell.idx)
        cell.mine_count = count(x->x.has_mine, neighbors)
    end
    return nothing
end

get_neighbors(game::Game, idx) = get_neighbors(game.cells, idx.I...)
get_neighbors(game::Game, cell::Cell) = get_neighbors(game.cells, cell.idx.I...)
get_neighbors(game::Game, x, y) = get_neighbors(game.cells, x, y)
get_neighbors(cells, idx) = get_neighbors(cells, idx.I...)

function get_neighbors(cells, xr, yr)
    v = [-1,0,1]
    X = xr .+ v; Y = yr .+ v
    neighbors = Vector{Cell}()
    for y in Y, x in X
        (x == xr) && (y == yr) ? (continue) : nothing
        in_bounds(cells, x, y) ? push!(neighbors, cells[x,y]) : nothing
    end
    return neighbors
end

get_neighbor_indices(game::Game, idx) = get_neighbor_indices(game.cells, idx.I...)
get_neighbor_indices(game::Game, x, y) = get_neighbor_indices(game.cells, x, y)
get_neighbor_indices(cells, idx) = get_neighbor_indices(cells, idx.I...)

function get_neighbor_indices(cells, xr, yr)
    v = [-1,0,1]
    X = xr .+ v; Y = yr .+ v
    neighbors = Vector{CartesianIndex}()
    for y in Y, x in X
        (x == xr) && (y == yr) ? (continue) : nothing
        in_bounds(cells, x, y) ? push!(neighbors, CartesianIndex(x,y)) : nothing
    end
    return neighbors
end

function in_bounds(cells, x, y)
    if (x < 1) || (y < 1)
        return false
    elseif (x > size(cells, 1)) || (y > size(cells, 2))
        return false
    else
        return true
    end
end

reveal_zeros!(game::Game, x, y) = reveal_zeros!(game.cells, CartesianIndex(x, y))
reveal_zeros!(game::Game, idx) = reveal_zeros!(game.cells, idx)

function reveal_zeros!(cells, idx)
    cells[idx].mine_count ≠ 0 ? (return nothing) : nothing
    indices = get_neighbor_indices(cells, idx)
    for i in indices
        c = cells[i]
        if !c.has_mine && !c.revealed
            c.revealed = true
            c.mine_count == 0 ? reveal_zeros!(cells, i) : nothing
        end
    end
    return nothing
end

reveal(game::Game) = reveal(game.cells::Array{Cell,2})

"""
    reveal(cells::Array{Cell,2})

Reveals game state in REPL
"""
function reveal(cells::Array{Cell,2})
    s = ""
    for x in 1:size(cells,1)
        for y in 1:size(cells,2)
            c = cells[x,y]
            if c.has_mine
                s *= string(" ", "💣", " ")
            else
                s *= string(" ", c.mine_count, " ")
            end
        end
        s *= "\r\n"
    end
    println(s)
end

Base.show(io::IO, game::Game) = Base.show(io::IO, game.cells)

function Base.show(io::IO, cells::Array{Cell,2})
    s = ""
    for x in 1:size(cells,1)
        for y in 1:size(cells,2)
            c = cells[x,y]
            if c.flagged
                s *= string(" ", "🚩", " ")
                continue
            end
            if c.revealed
                if c.has_mine
                    s *= string(" ", "💣", " ")
                    continue
                end
                if c.mine_count == 0
                    s *= string(" ", "∘", " ")
                else
                    s *= string(" ", c.mine_count, " ")
                end
            else
                s *= string(" ", "■", " ")
            end
        end
        s *= "\r\n"
    end
    println(s)
end

"""
    game_over(game)

Terminates game if mine is detonated or all cells have been revealed or flagged.
"""
function game_over(game)
    if game.mine_detonated
        return true
    end
    return all(x->x.revealed || x.flagged, game.cells)
end

"""
    compute_score!(game)

Computes hits, false alarms, misses and correct rejections
"""
function compute_score!(game)
    cells = game.cells
    n_mines = game.n_mines
    no_mines = prod(game.dims) - n_mines
    hits = count(x->x.flagged && x.has_mine, cells)
    misses = n_mines - hits
    false_alarms = count(x->x.flagged && !x.has_mine, cells)
    cr = no_mines - false_alarms
    game.score = (hits=hits,false_alarms=false_alarms,misses=misses,correct_rejections=cr)
    return nothing
end

"""
    select_cell!(game, x, y)
    
Select cell given a game and row and column indices.
"""
select_cell!(game, x, y) = select_cell!(game, CartesianIndex(x, y))

"""
    select_cell!(game, x, y)
    
Select cell given a game and cell object.
"""
select_cell!(game, cell::Cell) = select_cell!(game, cell.idx)

"""
    select_cell!(game, idx)

Select cell given a game and Cartesian index.
"""
function select_cell!(game, idx)
    cell = game.cells[idx]
    cell.revealed = true
    reveal_zeros!(game, idx)
    game.mine_detonated = cell.has_mine
    return nothing
end

function flag_cell!(cell, game, gui::Nothing)
    cell.flagged = true
    game.mines_flagged += 1
    return nothing
end

function setup()
    println("Select Difficulty")
    waiting = true
    levels = [20,50,70]
    i = 0
    while waiting
        d = input("1: easy 2: medium, 3: difficult")
        i = parse(Int, d)
        if i ∉ 1:3
            println("Please select 1, 2, or 3")
        else
            waiting = false
        end
    end
    return Game(;dims=(15,15), n_mines=levels[i])
end

function play()
    game = setup()
    play(game)
end

"""
    play(game)

Play Minesweeper in REPL

Run play() to use with default easy, medium and difficult settings
Pass game object to play custom game
Enter exit to quit
Enter row_index column_index to select cell (e.g. 1 2)
"""
function play(game)
    playing = true
    coords = fill(0, 2)
    println(game)
    while playing
        str = input("select coordinates")
        str == "exit" ? (return) : nothing
        try
            coords = parse.(Int, split(str, " "))
        catch
            error("Please give x and y coordinates e.g. 3 2")
        end
        select_cell!(game, coords...)
        if game.mine_detonated
            reveal(game)
            println("Game Over")
            println(" ")
            d = input("Press y to play again")
            d == "y" ? (game = setup()) : (playing = false)
        else
            println(game)
        end
    end
end

function input(prompt)
    println(prompt)
    return readline()
end

"""
    update!(game, gui::Nothing)

`update!` is used to display game state during simulations.
`update!` can be used with REPL or Gtk GUI if imported via import_gui()
"""
function update!(game, gui::Nothing)
    println(game)
end

"""
imports Gtk related code for the GUI
"""
function import_gui()
    path = @__DIR__
    include(path*"/Gtk_Gui.jl")
end
