using Minesweeper

import_gui()

# simple model that selects random location and flags it with probablity θflag
# and clears it with probability 1-θflag
struct Model
    θflag::Float64
end

function select_random_cell(game)
    unselected = findall(x->!x.revealed && !x.flagged, game.cells)
    return rand(unselected)
end

function flag!(game, choice)
    game.cells[choice].flagged = true
end

# simulate game
function run!(game; realtime=false, gui=nothing)
    detonated = false
    realtime ? update!(game, gui) : nothing
    while !detonated && !game_over(game)
        choice = select_random_cell(game)
        if rand() <= model.θflag
            flag!(game, choice)
        else
            detonated = select_cell!(game, choice)
        end
        realtime ? update!(game, gui) : nothing
        game.trials += 1
    end
    compute_score!(game)
    return nothing
end

#Run with GUI
model = Model(.5)
game = Game(dims=(10,10), n_mines=15, pause=.5)
gui = generate_gui(game)
run!(game, gui=gui, realtime=true)
println(game.score)

#Run with REPL print out
model = Model(.5)
game = Game(dims=(10,10), n_mines=15, pause=.5)
run!(game, realtime=true)
println(game.score)

#Run without GUI
model = Model(.5)
game = Game(dims=(10,10), n_mines=15, pause=.5)
run!(game)
println(game.score)
