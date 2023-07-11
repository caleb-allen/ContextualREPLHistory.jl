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

using Dates, TimeZones
struct HistoryEntry
    content::String
    time::Tuple{DateTime,String} # timezone
    mode::String
    dir::Union{String,Nothing}
end

time(entry::HistoryEntry) = Dates.format(entry.time[1], dateformat"YYYY-mm-dd HH:MM:SS ") * entry.time[2]
content(entry::HistoryEntry) = replace(entry.content, r"^"ms => "\t")


function parse_time(time::String)::Tuple{DateTime,String}
    time_parts = split(time)
    t = join(time_parts[begin:end-1], " ")
    time = DateTime(t, dateformat"YYYY-mm-dd HH:MM:SS")
    tz = String(time_parts[end])
    return (time, tz)
    # df = Dates.DateFormat()
    # tz = TimeZone(time[end-3:end])
    # ZonedDateTime(time, "YYYY-mm-dd HH:MM:SSZ")
end
# time: $(Libc.strftime(, time()))
HistoryEntry(content::String, time::String, mode::String, dir::Union{String,Nothing}=nothing) =
    HistoryEntry(content, parse_time(time), mode, dir)
HistoryEntry(;content::String, time::String=error("time parameter not set"),
    mode::String=error("Mode should be set"),
    dir::Union{String,Nothing}=nothing) =
    HistoryEntry(content, parse_time(time), mode, dir)

HistoryEntry(s::AbstractString) = HistoryEntry(IOBuffer(s))
function HistoryEntry(buf::IO, args=[], content=String[])
    time = nothing
    mode = nothing
    dir = nothing

    finished_metadata = false
    empty!(args)
    empty!(content)
    i = 0
    while !eof(buf)
        i > 5 && break
        i += 1
        # we don't want to keep reading past an entry
        if finished_metadata && peek(buf, Char) == '#'
            break
        end
        line = readline(buf)
        if !finished_metadata && is_metadata(line)
            arg = metadata(line)
            push!(args, arg)
        else
            finished_metadata = true
            @info "line" line escape_string(line)
            code_line = match(r"\s(.*)", line)
            # (code_line === nothing || length(code_line.captures) == 1) && error("Error while parsing line: `$(escape_string(line))`")
            push!(content, code_line.captures[1])
            @info "matches" code_line line
            # push!(content, line)
        end
    end
    # HistoryEntry(time, mode, dir, join(content, "\n"))
    HistoryEntry(content=join(content, "\n"); args...)
end

function is_metadata(line::AbstractString)::Bool
    rx = r"# (time|mode|dir): .*"
    match(rx, line) !== nothing
end

function metadata(line::AbstractString)::Tuple{Symbol,String}
    m = match(r"# (.+?): (.*)", line)
    type = m.captures[1] |> Symbol
    @assert type in (:time, :mode, :dir)
    data = m.captures[2]
    return (type, data)
end

function entries(history_file=HISTORY_NAME)::Vector{HistoryEntry}
    entries = []
    metadata_lines = 0

    time = ""
    mode = ""
    dir = nothing
    content = []
    for line in eachline(history_file)
        if is_metadata(line)
            type = metadata(line)
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
                        HistoryEntry(join(content, "\n"), time, mode, dir))
                end
                # # reset for a new entry
                # time = line
                # mode = ""

                dir = nothing
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
    println(io, "# time: " * time(e))
    println(io, "# mode: " * e.mode)
    print(io, content(e))
end
function write_annotated(io::IO, e::HistoryEntry)
    println(io, "# dir: " * e.dir)
    println(io, "# time: " * time(e))
    println(io, "# mode: " * e.mode)
    print(io, content(e))
end
function Base.show(io::IO, ::MIME"text/plain", e::HistoryEntry)
    if e.dir === nothing
        write(io, e)
    else
        write_annotated(io, e)
    end
end


