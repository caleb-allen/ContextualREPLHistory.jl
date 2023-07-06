#!/usr/bin/env julia
#
# Find any Julia history entries with control sequences that corrupt the REPL state.
# By default, print the lines which are corrupted.
#
# usage: ./fix_history.jl [--delete_corrupted, --escape_corrupted]
#
# --delete_corrupted: remove entries which are corrupted from history.
#
# --escape_corrupted: sanitize the entries which are corrupted so that the corrupted
# entries are still in history but can be safely displayed on the terminal.
#
# using  will copy the contents of `repl_history.jl` with the corrupted
# entries removed. A backup file will be created at `repl_history_backup.jl`
# prior to any modifications.


struct HistoryEntry
    time::String
    mode::String
    dir::String
    content::String
end

function is_hist_metadata(line::AbstractString)::Bool
    rx = r"# (time|mode|dir): .*"
    match(rx, line) !== nothing
end

function metadata_type(line::AbstractString)::Symbol
    m = match(r"# (.+?):.*", line)
    return m.captures[1] |> Symbol
end

function entries(history_file=HISTORY_NAME)::Vector{HistoryEntry}
    entries = []
    metadata_lines = 0

    time = ""
    mode = ""
    dir = "# dir:"
    content = []
    for line in eachline(history_file)
        if is_hist_metadata(line)
            type = metadata_type(line)
            @assert type in (:time, :mode, :dir)
            if type == :mode
                mode = line
            elseif type == :time
                time = line
            elseif type == :dir
                dir = line
            end
            if metadata_lines == 0
                if time !== "" && mode !== ""
                    # create an entry value if necessary
                    push!(entries,
                        HistoryEntry(time, mode, dir, join(content, "\n")))
                end
                # # reset for a new entry
                # time = line
                # mode = ""
                dir = "# dir:"
                empty!(content)
            end
            metadata_lines += 1
        else
            metadata_lines = 0
            push!(content, line)
        end
    end
    entries
end

function write_history(entries::Vector{HistoryEntry})
    backup_file = joinpath(homedir(), ".julia/logs/repl_history_backup.jl")
    cp(history_file, backup_file)
    println("copied $history_file to $backup_file")

    out_file = history_file
    rm(history_file)
    touch(history_file)
    open(out_file, "w") do io
        for entry in entries
            write(io, entry)
            write(io, "\n")
        end
    end
    return out_file
end

function Base.write(io::IO, e::HistoryEntry)
    print(io, e.time * "\n" * e.mode * "\n" * e.content)
end
function Base.show(io::IO, ::MIME"text/plain", e::HistoryEntry)
    # if is_corrupted(e)
    #     println(io, "\t" * e.time * "\n\t" * e.mode * "\n\t\t" * escape_string(e.content))
    # else
        println(io, "\t" * e.time * "\n\t" * e.mode * "\n\t" * e.dir * "\n\t" * e.content)
    # end
end


