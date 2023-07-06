using ContextualREPLHistory
const C = ContextualREPLHistory
using Test

@testset "ContextualREPLHistory.jl" begin
    
    @test C.metadata_type(" # time: 2023-07-06 14:28:08 BST") == :time
    @test C.metadata_type(" # mode: julia") == :mode
    @test C.metadata_type(" # dir: /home") == :dir
    # Write your tests here.
end
