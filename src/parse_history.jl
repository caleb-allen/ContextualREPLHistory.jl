
"""
Parse the history entries at `path`
"""
function parse_history(path=HISTORY_NAME)::Vector{HistoryEntry}
    entries = HistoryEntry[]
    i = 0
    args = []
    content = String[]
    try
        open(path) do f
            while !eof(f)
                entry = HistoryEntry(f, args, content)
                push!(entries, entry)
                i += 1
            end
        end
    catch ex
        @error "Error while parsing history entry" iteration=i last=entries[end] content=(join(content, "\n")) args exception=(ex, backtrace()) 
        # throw(ex)
    end
    return entries
end
