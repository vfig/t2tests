Object_Description <- function(obj)
{
    local name;
    if (obj == 0) {
        name = "[nothing]";
    } else {
        name = Object.GetName(obj);
        if (name == "") {
            // Look up the archetype's name instead.
            local archetype_name = Object.GetName(Object.Archetype(obj));
            if (archetype_name == "") {
                name = "[unknown]";
            } else {
                local first = archetype_name.slice(0, 1).toupper();
                if (first == "A" || first == "E" || first == "I" || first == "O" || first == "U") {
                    name = "an " + archetype_name;
                } else {
                    name = "a " + archetype_name;
                }
            }
        }
    }
    return (name + " (" + obj + ")");
}

/* Get the ScriptParams link with the given data */
Link_GetOneScriptParams <- function(data = "", from = 0, to = 0)
{
    local links = Link.GetAll("ScriptParams", from, to);
    foreach (link in links) {
        local link_data = LinkTools.LinkGetData(link, "");
        if (link_data == data) {
            return link;
        }
    }
    return 0;
}

/* Get all ScriptParams links with the given data */
Link_GetAllScriptParams <- function(data = "", from = 0, to = 0)
{
    local links = Link.GetAll("ScriptParams", from, to);
    local matching_links = [];
    foreach (link in links) {
        local link_data = LinkTools.LinkGetData(link, "");
        if (link_data == data) {
            matching_links.append(link);
        }
    }
    return matching_links;
}

/* Get the ~ScriptParams link with the given data */
Link_GetOneInverseScriptParams <- function(data = "", from = 0, to = 0)
{
    local links = Link.GetAll("~ScriptParams", from, to);
    foreach (link in links) {
        local link_data = LinkTools.LinkGetData(link, "");
        if (link_data == data) {
            return link;
        }
    }
    return 0;
}

/* Get the dest of the ScriptParams link with the given data */
Link_GetOneParam <- function(data = "", from = 0)
{
    return LinkDest(Link_GetOneScriptParams(data, from));
}

/* Get the destinations of all ScriptParams links with the given data */
Link_GetAllParams <- function(data = "", from = 0)
{
    local links = Link_GetAllScriptParams(data, from);
    return links.map(LinkDest);
}
