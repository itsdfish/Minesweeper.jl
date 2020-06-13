using Gtk

"""
Creates game in GUI.
Default game is: Game(dims=(10,10), n_mines=15)
Pass game object for custom game
Start new game: File->New Game
Game setup: File->Setup
Flagging: switch on and off using toggle slider in top left corner
"""
function generate_gui()
    game = Game(dims=(10,10), n_mines=15)
    generate_gui(game)
end

function generate_gui(game)
    win = GtkWindow("Minesweeper")
    generate_gui!(game, win)
    return win
end

function generate_gui!(game, win)
    menu_bar = setup_menu(win, game)
    g = GtkGrid(name="grid")
    base_panel = GtkBox(:v, name="base_panel")
    score_panel = GtkBox(:h, name="score_panel")
    toggle_panel = GtkBox(:h, name="toggle_panel")
    push!(base_panel, menu_bar)
    push!(base_panel, score_panel)
    push!(base_panel, toggle_panel)
    set_gtk_property!(score_panel, :spacing, 20)
    set_gtk_property!(toggle_panel, :spacing, 20)
    label = GtkLabel("Mines flagged ", name="mines_flagged_label")
    push!(score_panel, label)
    flag_label = GtkLabel("0", name="flag_counter")
    push!(score_panel, flag_label)
    push!(base_panel, g)
    toggle = Gtk.GtkSwitch()
    signal_connect(set_toggle, toggle, "activate")
    toggle_label = GtkLabel("Flagging")
    push!(toggle_panel, toggle_label)
    push!(toggle_panel, toggle)
    for r in 1:game.dims[1], c in 1:game.dims[2]
        b = GtkButton("")
        g[r,c] = b
        signal_connect(x->on_button_clicked(x, game, win, game.cells[c,r], toggle), b, "clicked")
    end
    set_gtk_property!(g, :column_spacing, 5)  # introduce a 15-pixel gap between columns
    set_gtk_property!(g, :row_spacing, 5)
    set_gtk_property!(g, :column_homogeneous, true)
    set_gtk_property!(g, :row_homogeneous, true)
    set_gtk_property!(g, :expand, true)
    set_gtk_property!(score_panel, :pack_type, label, 0)
    push!(win, base_panel)
    showall(win)
end

function on_button_clicked(button, game, gui, cell, toggle)
    game.mine_detonated ? (return nothing) : nothing
    flag_on = get_gtk_property(toggle, :state, Bool)
    if flag_on
        counter = gui[1][2][2]
        if cell.flagged
            set_gtk_property!(button, :label, "")
            game.mines_flagged -= 1
        else
            set_gtk_property!(button, :label, "🚩")
            game.mines_flagged += 1
        end
        set_gtk_property!(counter, :label, string(game.mines_flagged))
        cell.flagged = !cell.flagged
        return nothing
    end
    grid = gui[1][4]
    if cell.flagged
    elseif cell.has_mine
        game.mine_detonated = true
        cell.revealed = true
        reveal_button!(grid, cell, "💣")
    elseif cell.mine_count == 0
        cell.revealed = true
        reveal_button!(grid, cell, "∘")
        cells = game.cells
        indices = get_neighbor_indices(game, cell.idx)
        for i in indices
            c = cells[i]
            if !c.has_mine && !c.revealed
                on_button_clicked(button, game, gui, c, toggle)
            end
        end
    else
        cell.revealed = true
        reveal_button!(grid, cell, string(cell.mine_count))
    end
    return nothing
end

function set_toggle(button)
    println("setting toggle state")
    state = get_gtk_property(button, :state, String)
    set_gtk_property(button, :state, !state)
end

function update!(game, gui::GtkWindowLeaf)
    for c in game.cells
        if c.flagged
            flag_button!(gui, c)
        elseif c.revealed
            if c.has_mine
                reveal_button!(gui, c, "💣")
            elseif c.mine_count == 0
                reveal_button!(gui, c, "∘")
            else
                reveal_button!(gui, c, string(c.mine_count))
            end
        end
    end
    sleep(game.pause)
    return nothing
end

reveal_button!(win::GtkWindowLeaf, cell, value) = reveal_button!(win[1][4], reverse(cell.idx.I), value)

reveal_button!(buttons::GtkGridLeaf, cell::Cell, value) = reveal_button!(buttons, reverse(cell.idx.I), value)

function reveal_button!(buttons::GtkGridLeaf, idx, value)
    delete!(buttons, buttons[idx...])
    buttons[idx...] = GtkLabel(value)
    set_gtk_property!(buttons[idx...], :visible, true)
end

flag_button!(win::GtkWindowLeaf, cell) = flag_button!(win[1][4], reverse(cell.idx.I))

function flag_button!(buttons, idx)
    set_gtk_property!(buttons[idx...], :label, "🚩")
end

start_new_game!(x, gui, game) = start_new_game!(gui, game)

function start_new_game!(gui, game)
    game.score = (hits=0.0,false_alarms=0.0,misses=0.0,correct_rejections=0.0)
    cells = initilize_cells(game.dims)
    add_mines!(cells, game.n_mines)
    mine_count!(cells)
    game.cells = cells
    game.mines_flagged = 0
    game.mine_detonated = false
    remove_components!(gui)
    generate_gui!(game, gui)
end

function setup_menu(gui, game)
    mb = GtkMenuBar(name="menu_bar")
    file = GtkMenuItem("_File")
    file_menu = GtkMenu(file, name="file_menu")
    new_game = GtkMenuItem("New Game", name="new_game")
    signal_connect(x->start_new_game!(x, gui, game), new_game, :activate)
    push!(file_menu, new_game)
    setup = GtkMenuItem("Setup", name="setup")
    signal_connect(x->setup_game(x, game, gui), setup, :activate)
    push!(file_menu, setup)
    push!(mb, file)
    return mb
end

function remove_components!(gui)
    for g in gui
        delete!(gui, g)
    end
end

function setup_game(x, game, gui)
    popup = GtkWindow("Setup")
    base_panel = GtkBox(:v)
    push!(popup, base_panel)
    grid = GtkGrid()
    col_label = GtkLabel("Number of Columns")
    row_label = GtkLabel("Number of Rows")
    mine_label = GtkLabel("Number of Mines")
    col_entry = GtkEntry(name="col_value")
    row_entry = GtkEntry(name="row_value")
    mine_entry = GtkEntry(name="mine_value")
    grid[1,1] = col_label
    grid[2,1] = col_entry
    grid[1,2] = row_label
    grid[2,2] = row_entry
    grid[1,3] = mine_label
    grid[2,3] = mine_entry
    GAccessor.justify(col_label, Gtk.GConstants.GtkJustification.LEFT)
    GAccessor.justify(row_label, Gtk.GConstants.GtkJustification.LEFT)
    set_gtk_property!(grid, :column_spacing, 5)  # introduce a 15-pixel gap between columns
    set_gtk_property!(grid, :row_spacing, 5)
    set_gtk_property!(grid, :column_homogeneous, true)
    set_gtk_property!(grid, :row_homogeneous, true)
    push!(base_panel, grid)
    ok_button = GtkButton("OK")
    components = (col_entry=col_entry, row_entry=row_entry, mine_entry=mine_entry, popup=popup)
    signal_connect(x-> modify_game(x, components, game, gui), ok_button, "clicked")
    cancel_button = GtkButton("Cancel")
    signal_connect(x->close_window(x, popup), cancel_button, "clicked")
    hbox = GtkButtonBox(:h)
    set_gtk_property!(hbox, :expand, ok_button, true)
    set_gtk_property!(hbox, :spacing, 10)
    push!(base_panel, hbox)
    push!(hbox, cancel_button)
    push!(hbox, ok_button)
    showall(popup)
end

function modify_game(x, c, game, gui)
    str_cols = get_gtk_property(c.col_entry, :text, String)
    n_cols = parse(Int, str_cols)
    str_rows = get_gtk_property(c.row_entry, :text, String)
    n_rows = parse(Int, str_rows)
    str_mines = get_gtk_property(c.mine_entry, :text, String)
    n_mines = parse(Int, str_mines)
    if n_mines > n_rows*n_cols
        error_window = GtkWindow("Error")
        base_panel = GtkBox(:v)
        set_gtk_property!(base_panel, :spacing, 20)
        message = GtkLabel(
            "The number of mines cannot exceed the number of cells"
        )
        ok_button = GtkButton("OK")
        push!(error_window, base_panel)
        push!(base_panel, message)
        push!(base_panel, ok_button)
        signal_connect(x->close_window(x, error_window), ok_button, "clicked")
        showall(error_window)
        return nothing
    end
    game.dims = (n_rows,n_cols)
    game.n_mines = n_mines
    start_new_game!(gui, game)
    close_window(c.popup)
    return nothing
end

close_window(_, component) = close_window(component)

function close_window(component)
    hide(component)
end
