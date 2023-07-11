using ContextualREPLHistory
const C = ContextualREPLHistory
using Test, Dates

@testset "ContextualREPLHistory.jl" begin

    # @test C.metadata_type(" # time: 2023-07-06 14:28:08 BST") == :time
    # @test C.metadata_type(" # mode: julia") == :mode
    # @test C.metadata_type(" # dir: /home") == :dir
    # Write your tests here.
end

@testset "Parse time" begin
    # C.parse_time("2023-07-06 14:39:13 BST") = DateTime(2023, 7, 6, 14, 39, 13,)

end

@testset "Parse buf, write it, and parse it again" begin
    raw_entry = """# dir: /home/caleb/.julia/dev/ContextualREPLHistory
# time: 2023-07-06 14:39:13 BST
# mode: julia
\t"test
\tline2\""""
    he = HistoryEntry(raw_entry)
    @test content(he) == "\t\"test\n\tline2\""
    
    buf = IOBuffer()
    write(buf, he)
    seek(buf, 0)
    re_written = read(buf, String)
    
    @test s == raw_entry
end

@testset "Parse a history entry" begin
    s = """
# time: 2023-07-06 14:39:13 BST
# mode: julia
\t"test\"""" |> chomp
    @test C.HistoryEntry(s) == HistoryEntry("2023-07-06 14:39:13 BST",
        "julia",
        nothing,
        "\t\"test\"")
    he = HistoryEntry(
        """
        # time: 2023-07-06 14:39:13 BST
        # mode: julia
               "test\"""")

end


