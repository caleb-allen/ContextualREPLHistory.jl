module ContextualREPLHistory

using Base.Threads
import Base.Threads.@spawn
using REPL
import REPL.LineEdit as LE
export start, stop, unload_proxy, annotate_history, HistoryEntry

const HISTORY_NAME = REPL.find_hist_file()

include("history_entry.jl")
include("parse_history.jl")

struct ReplContext
    dir::AbstractString
    git_branch::Union{Nothing,AbstractString}
end

# Base.active_repl.interface.modes[1].hist.history
# repl_hist() = 
# error happening on entry at
# time: 2021-03-30 12:58:10 PDT
"""
- Intercept the history file to be loaded
- Re-order the history entries according to the context
- Write the re-sorted history to the proxy
"""
function init()
    # load_proxy()
    
    context_name = context_filename()
    ispath(context_name) || cp(HISTORY_NAME, context_name)
    @info "Parsing history" context_name
    entries = parse_history(context_name)
    
    # @info "Sorting" by="string"
    # sort!(entries, by=e->e.content; rev=true)
    
    # @info "Sorting" by="time"
    # sort!(entries, by=e->e.time[1]; rev=true)

    proxy_path = proxy_filename()
    ispath(proxy_path) && rm(proxy_path)
    touch(proxy_path)
    load_proxy(entries)
    ENV["JULIA_HISTORY"] = proxy_path
    @info "loaded proxy history" proxy_path
    
    # write_entries(entries, )
end

function start(repl)
    unload_proxy(repl)

    t = @spawn annotate_history()
    errormonitor(t)
    
end

function load_proxy(entries=parse_history())
    atexit() do
        WATCHING[] = false
    end
    path = proxy_filename()
    @info "Loading proxy history" path
    
    open(path, "w") do proxy
        write(proxy, entries)
        flush(proxy)
    end
end

function unload_proxy(repl)
    hp::REPL.REPLHistoryProvider = LE.mode(repl.mistate).hist

    hp.file_path = HISTORY_NAME
    ENV["JULIA_HISTORY"] = HISTORY_NAME

    # reset the repl to write to the standard history
    close(hp.history_file)
    f = open(hp.file_path, read=true, write=true, create=true)
    hp.history_file = f
    seekend(f)
end

function context_filename(history_filename=REPL.find_hist_file())
    paths = splitpath(history_filename)
    context_filename = "annotated_" * paths[end]
    return joinpath([paths[begin:end-1]; context_filename])
end

function proxy_filename(history_filename=REPL.find_hist_file())
    paths = splitpath(history_filename)
    return joinpath([paths[begin:end-1];".proxy_" * paths[end]])
end

function stop()
    WATCHING[] = false
end

const WATCHING = Ref{Bool}(true)

"""
    Proxy the HistoryProvider'
"""
function annotate_history(history_name=HISTORY_NAME)
    ctx_file = open(context_filename(), write=true)
    seekend(ctx_file)

    try
        open(`tail -F $history_name`, read=true) do io
            @info "io" io typeof(io)

            while WATCHING[]
                # data = readline(io)
                if eof(io)
                    # sleep(0.5)
                    @info "eof. continue"
                    continue
                end
                data = readavailable(io) |> String
                @info "reading history" data io

                dir = " # dir: " * pwd()
                println(ctx_file, dir)
                print(ctx_file, data)
                flush(ctx_file)
            end
        end
        return
    finally
        close(ctx_file)
    end
end


function debug()
    
    # run(`tail -F contextual_proxy_repl_history.jl`)
end
end
