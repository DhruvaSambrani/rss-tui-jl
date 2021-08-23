using LightXML
import Downloads
using Gumbo
using AbstractTrees

if_nothing(nothing_f, not_nothing_f, x) = isnothing(x) ? nothing_f() : not_nothing_f(x)
download_string(url) = String(take!(Downloads.download(url, IOBuffer())))

struct Feed
    title
    link
    desc
    items
end

function Feed(xml)
    channelnode = find_element(xml, "channel")
    title = content(find_element(channelnode, "title"))
    link = content(find_element(channelnode, "link"))
    desc = content(find_element(channelnode, "description"))
    items = get_items(xml)
    Feed(title, link, desc, items)
end

struct FeedItem
    title
    link
    desc
    author
end

function get_content(f::FeedItem)
    if_nothing(identity, f.desc) do 
        s = download_string(f.link)
        body = (parsehtml(s).root)[2]
        it = PreOrderDFS(body, i-> !(i isa HTMLElement{:div})) |> collect
        contentdiv = filter(it) do i
            i isa HTMLElement{:div} && getattr(i, "id", "") == "content";
        end
        prod(i->text(i)*"\n", filter(i->i isa HTMLText, Leaves(contentdiv) |> collect))
    end
end

function FeedItem(itemnode)
    title = content(find_element(itemnode, "title"))
    desc = if_nothing(() -> nothing, content, find_element(itemnode, "description"))
    link = content(find_element(itemnode, "link"))
    author = if_nothing(() -> "", content, find_element(itemnode, "author"))
    FeedItem(title, link, desc, author)
end

get_feed(url) = root(parse_string(download_string(url)))

get_items(xml) = FeedItem.(get_elements_by_tagname(xml, "item"))


