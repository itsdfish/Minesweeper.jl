using Minesweeper

# play in REPL
# enter coordinates as: row_index column_index
play()

# pass custom game to play
game = Game(dims=(20,10), n_mines=35)
play(game)
