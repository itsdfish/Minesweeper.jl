using Minesweeper

# generate game object
game = Game(dims=(10,10), n_mines=15)

# reveal game contents in REPL
reveal(game)

# select cell
select_cell!(game, 1, 2)

# print game to REPL
println(game)
