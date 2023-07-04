module ContextualREPLHistory

using Base.Threads
import Base.Threads.@spawn
using REPL
import REPL.LineEdit as LE
export init, stop

struct ReplContext
    dir::AbstractString
    git_branch::Union{Nothing,AbstractString}
end

hist_file = REPL.find_hist_file()
function init()
    PROXYING[] = true
    @show history_name = REPL.find_hist_file()
    @show proxy_filename = proxy_hist_filename(history_name)
    rm(proxy_filename)
    touch(proxy_filename)
    ENV["JULIA_HISTORY"] = proxy_filename
    @spawn begin
        try
            proxy_history_file(history_name, proxy_filename)
        catch ex
            @error "History proxying failed" exception = (ex, catch_backtrace())
        end
    end
    # read in the REPL history...
end
proxy_hist_filename(history_name) = [splitpath(history_name)[1:end-1]; "repl_context_proxy.jl"] |> joinpath

function stop()
    PROXYING[] = false
end

const PROXYING = Ref{Bool}(true)

"""
    Proxy the HistoryProvider'
"""
function proxy_history_file(history_name::AbstractString, proxy_name::AbstractString)
    # proxy = IOBuffer()
    # pipe = run(pipeline(`tail -F $proxy_name`, stdout=proxy), wait=false)
    # cmd = `tail -F $proxy_name`
    # @show pipe

    process = open(`tail -F $proxy_name`, read=true) do io
        @info "io" io typeof(io)

        while PROXYING[]
            # data = readline(io)
            if eof(io)
                # sleep(0.5)
                @info "eof. continue"
                continue
            end
            data = readavailable(io) |> String
            @info "reading proxy" data io
            # sleep(2)
        end
    end
    @info "process" process typeof(process)
    return
end

end
