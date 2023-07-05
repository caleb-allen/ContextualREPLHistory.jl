using REPL.LineEdit
import LineEdit: HistoryProvider
import REPL: REPLHistoryProvider
# This approach likely won't work because REPL.jl dispatches on REPLHistoryProvider, not on
# HistoryProvider
mutable struct ContextualREPLHistoryProvider <: HistoryProvider
    default_history_provider::REPLHistoryProvider
end