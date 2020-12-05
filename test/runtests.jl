using SafeTestsets

@safetestset "Mine Count" begin
    using Test, Random, Minesweeper
    Random.seed!(6564)
    n_mines = 3
    game = Game(dims=(5,5), n_mines=n_mines)
    @test n_mines == count(x->x.has_mine, game.cells)
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

    Random.seed!(6564)
    game = Game(dims=(5,5), n_mines=3)
    reveal_zeros!(game, 3, 2)
    @test count(x->x.revealed, game.cells) == 0

    Random.seed!(6564)
    game = Game(dims=(5,5), n_mines=3)
    reveal_zeros!(game, 1, 4)
    @test count(x->x.revealed, game.cells) == 6
    revealed_indices = ((1,3),(1,4),(1,5),(2,3),(2,4),(2,5))
    for i in revealed_indices
        @test game.cells[i...].revealed
    end
    revealed = filter(x->x.revealed, game.cells)
    @test !any(x->x.has_mine, revealed)
end
