include("feedparser.jl")
include("tui.jl")

function main()
    feeds = ["http://export.arxiv.org/rss/quant-ph", "http://feeds.nature.com/nature/rss/current"]
    TUI.initialize()
    e = nothing
    try
        t = TUI.Terminal()
        while true
            url = display_feedlist(feeds, t)
            isnothing(url) && break  
            display_feed(Feed(get_feed(url)), t) 
        end
    catch ex
        e = ex
        TUI.cleanup()
        rethrow(e)
    end
    TUI.cleanup()
end

main()


