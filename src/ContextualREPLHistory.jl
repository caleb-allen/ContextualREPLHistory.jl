module ContextualREPLHistory

using Base.Threads
import Base.Threads.@spawn
using REPL
import REPL.LineEdit as LE
export load_proxy, stop, unload_proxy, annotate_history

const HISTORY_NAME = REPL.find_hist_file()

include("fix_history.jl")

struct ReplContext
    dir::AbstractString
    git_branch::Union{Nothing,AbstractString}
end

# hist_file = REPL.find_hist_file()
function load_proxy()
    atexit() do
        WATCHING[] = false
    end
    # PROXYING[] = true
    # @show proxy = context_filename(HISTORY_NAME)
    _, proxy = mktemp()
    ENV["JULIA_HISTORY"] = proxy
    # t = @spawn begin
    # proxy_history_file(history_name, context_filename)
    # end
    # errormonitor(t)
    # read in the REPL history...
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
    context_filename = "contextual_proxy_" * paths[end]
    return joinpath([paths[begin:end-1]; context_filename])
end
function stop()
    WATCHING[] = false
end

const WATCHING = Ref{Bool}(true)

"""
    Proxy the HistoryProvider'
"""
function annotate_history(history_name=HISTORY_NAME,
                          context_name=context_filename())
    # proxy = IOBuffer()
    # pipe = run(pipeline(`tail -F $context_name`, stdout=proxy), wait=false)
    # cmd = `tail -F $context_name`
    # @show pipe
    # history_file = open(history_name, write=true)
    # history_file = open(history_name, write=true)

    ispath(context_name) || cp(history_name, context_name)
    ctx_file = open(context_name, write=true)
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

                dir = " # dir: " * pwd() * "\n"
                print(ctx_file, dir)
                print(ctx_file, data)
                flush(ctx_file)
            end
        end
        return
    finally
        close(ctx_file)
    end
end


end
