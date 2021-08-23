using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Markdown
using Random

function get_displayable(item)
    title = TUI.make_words(item.title, TUI.Crayon(bold = true, foreground=:green))
    desc = TUI.make_words(get_content(item))
    author = TUI.make_words(item.author, TUI.Crayon(foreground = :blue))
    link = TUI.make_words(item.link, TUI.Crayon(italics = true))
    meta = [title; link; author]
    return meta, desc
end

get_absolute(p, _max) = round(Int, p*(_max-1)) + 1

function draw_article(item, scroll, t, fm = 0.2)
    TUI.clear_screen()
    TUI.hide_cursor()
    meta, desc = get_displayable(item)
    w, h = TUI.terminal_size()
    metaheight = get_absolute(fm, h)
    prog = TUI.ProgressBar(
        TUI.Block(title="Progress"),
        scroll,
        TUI.Crayon(foreground=:white, background=:blue)
    )
    content = TUI.Paragraph(
        TUI.Block(title="Content"),
        desc,
        1#get_absolute(scroll, h)
    ) 
    metablock = TUI.Paragraph(
        TUI.Block(title="Meta Data"),
        meta,
        1
    )
    TUI.draw(t, metablock, TUI.Rect(w÷3+2, 1, (2*w)÷3-2, metaheight))
    TUI.draw(t, content, TUI.Rect(w÷3+2, metaheight+2, (2*w)÷3-8, h-metaheight-5))
    TUI.draw(t, prog, TUI.Rect(w÷3+2, h-2, (2*w)÷3-2, 2))
end

function display_feedlist(feeds, t)
    y, x = 1, 1
    TUI.clear_screen()
    TUI.hide_cursor()
    words = TUI.Word.(feeds, Ref(TUI.Crayon()))

    scroll = 1
    selection = 1

    while true
        w, _ = TUI.terminal_size()
        r = TUI.Rect(x, y, w, 20)
        b = TUI.Block(title = "Select Feed")
        p = TUI.SelectableList(
            b,
            words,
            scroll,
            selection,
        )
        TUI.draw(t, p, r)
        TUI.flush(t, false)
        c = take!(t.stdin_channel)
        if c == 'j'
            selection += 1
        elseif c == 'k'
            selection -= 1
        elseif c == '\r'
            return words[selection].text
        elseif c == 'q'
            return nothing
        end
        selection = clamp(selection, 1, length(words))
    end
end

function draw_itemlist(titles, selection, t)
    w, h = TUI.terminal_size()
    titles = map(titles) do t; first(t, w÷3 - 6); end
    words = TUI.Word.(titles, (TUI.Crayon(),))
    r = TUI.Rect(1, 1, w ÷ 3, h)
    b = TUI.Block(title = "Select Feed")
    p = TUI.SelectableList(
        b,
        words,
        0,
        selection,
    )
    TUI.draw(t, p, r)
    p
end

function open_in_default_browser(url::AbstractString)::Bool
    try
        if Sys.isapple()
            Base.run(`open $url`)
            true
        elseif Sys.iswindows() || detectwsl()
            Base.run(`powershell.exe Start "'$url'"`)
            true
        elseif Sys.islinux()
            Base.run(`xdg-open $url`)
            true
        else
            false
        end
    catch ex
        false
    end
end

function display_feed(f, t)
    selection = 1
    scroll = 0
    while true
        draw_itemlist(getproperty.(f.items, :title), selection, t)
        draw_article(f.items[selection], scroll, t)
        TUI.flush(t, false)
        c = take!(t.stdin_channel)
        if c == 'j'
            scroll += 0.1
        elseif c == 'k'
            scroll -= 0.1
        elseif c == 'J'
            selection += 1
        elseif c == 'K'
            selection -= 1
        elseif c == 'l'
            open_in_default_browser(f.items[selection].link)
        elseif c == 'q'
            return nothing
        end
        scroll = clamp(scroll, 0, 1)
        selection = clamp(selection, 1, length(f.items))
    end
end
