using SafeTestsets

@safetestset "Mine Count" begin
    using Test, Random, Minesweeper
    Random.seed!(6564)
    n_mines = 3
    game = Game(dims=(5,5), n_mines=n_mines)
    @test n_mines == count(x -> x.has_mine, game.cells)
end

@safetestset "Neighbors" begin
    using Test, Minesweeper

    game = Game(dims=(5,5), n_mines=3)
    neighbors = get_neighbor_indices(game, 1, 1)
    @test length(neighbors) == 3

    neighbors = get_neighbor_indices(game, 2, 2)
    @test length(neighbors) == 8
    v = [-1,0,1]
    for Δx in v, Δy in v
        if (Δx == 0) & (Δy == 0)
            @test CartesianIndex(2 + Δx, 2 + Δy) ∉ neighbors
        else
            @test CartesianIndex(2 + Δx, 2 + Δy) ∈ neighbors
        end
    end
end

@safetestset "reveal zeros" begin
    using Test, Random, Minesweeper

    game = Game(dims=(5,5), n_mines=0)
    reveal_zeros!(game, 3, 2)
    @test count(x -> x.revealed, game.cells) == 25

    game = Game(dims=(5,5), n_mines=0)
    game.cells[1,2].has_mine = true 
    game.cells[2,1].has_mine = true 
    game.cells[2,2].has_mine = true
    mine_count!(game.cells) 
    select_cell!(game, 1, 1)
    @test count(x -> x.revealed, game.cells) == 1

    game = Game(dims=(5,5), n_mines=0)
    game.cells[1,2].has_mine = true 
    game.cells[2,1].has_mine = true 
    game.cells[2,2].has_mine = true
    mine_count!(game.cells) 
    select_cell!(game, 1, 2)
    @test count(x -> x.revealed, game.cells) == 1

    game = Game(dims=(5,5), n_mines=0)
    game.cells[1,2].has_mine = true 
    game.cells[2,1].has_mine = true 
    game.cells[2,2].has_mine = true
    mine_count!(game.cells) 
    select_cell!(game, 1, 4)
    @test count(x -> x.revealed, game.cells) == 21

    game = Game(dims=(5,5), n_mines=0)
    game.cells[1,3].has_mine = true 
    game.cells[3,5].has_mine = true 
    game.cells[4,4].has_mine = true
    game.cells[3,3].has_mine = true
    game.cells[2,3].has_mine = true
    mine_count!(game.cells)
    map(x -> x.has_mine, game.cells)
    select_cell!(game, 1, 5)

    @test count(x -> x.revealed, game.cells) == 4
    revealed_indices = ((1,4),(1,5),(2,4),(2,5))
    for i in revealed_indices
        @test game.cells[i...].revealed
    end
    revealed = filter(x -> x.revealed, game.cells)
    @test !any(x -> x.has_mine, revealed)
end

# @safetestset "gui tests" begin
#     using Test, Random, Minesweeper
#     Random.seed!(59808)
#     import_gui()
#     game = Game(dims=(10,10), n_mines=10)
#     gui = generate_gui(game)
#     cell = game.cells[1]
#     flag_cell!(cell, game, gui)
#     @test cell.flagged
#     @test game.mines_flagged == 1

#     idx = findfirst(x -> x.mine_count ==1, game.cells)
#     select_cell!(game, idx)
#     @test game.cells[idx].revealed

#     idx = findfirst(x -> x.has_mine, game.cells)
#     select_cell!(game, idx)
#     @test game.cells[idx].revealed
#     @test game.mine_detonated
#     @test game_over(game)
    
#     game = Game(dims=(10,10), n_mines=10)

#     for cell in game.cells
#         if cell.has_mine
#             cell.flagged = true
#         else
#             cell.revealed = true
#         end
#     end 
#     @test game_over(game)
# end