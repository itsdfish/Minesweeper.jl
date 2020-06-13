using Minesweeper

#import GUI functions
import_gui()

# Creates game in GUI.
# Default game is: Game(dims=(10,10), n_mines=15)
# Pass game object for custom game
# Start new game: File->New Game
# Game setup: File->Setup
# Flagging: switch on and off using toggle slider in top left corner
generate_gui()

# configure game in File-> Setup or pass custom game
game = Game(dims=(20,10), n_mines=35)
generate_gui(game)
