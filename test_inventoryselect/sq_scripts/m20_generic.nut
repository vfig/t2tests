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

/* Create a new ScriptParams link with the given data */
Link_CreateScriptParams <- function(data = "", from = 0, to = 0)
{
    local link = Link.Create("ScriptParams", from, to);
    LinkTools.LinkSetData(link, "", data);
    return link;
}

/* Get the AIConversationActor link with the given id */
Link_GetConversationActor <- function(actor_id, conversation)
{
    local links = Link.GetAll("AIConversationActor", conversation);
    foreach (link in links) {
        local link_data = LinkTools.LinkGetData(link, "Actor ID");
        if (link_data == actor_id) {
            return link;
        }
    }
    return 0;
}

Link_BroadcastOnAllLinks <- function(message, kind, from, data = 0, data2 = 0)
{
    local links = Link.GetAll(kind, from);
    foreach (link in links) {
        SendMessage(LinkDest(link), message, data, data2);
    }
}

Link_DestroyAll <- function(kind, from = 0, to = 0)
{
    local links = Link.GetAll(kind, from, to);
    foreach (link in links) {
        Link.Destroy(link);
    }
}

Link_GetCurrentPatrol <- function(ai)
{
    // AICurrentPatrol is a singleton link
    local link = Link.GetOne("AICurrentPatrol", ai);
    if (link != 0) {
        return LinkDest(link);
    } else {
        return 0;
    }
}

Link_SetCurrentPatrol <- function(ai, trol)
{
    // AICurrentPatrol is a singleton link, so make sure to delete any existing ones.
    Link_DestroyAll("AICurrentPatrol", ai);
    if (trol != 0) {
        Link.Create("AICurrentPatrol", ai, trol);
    }
}

Link_CollectPatrolPath <- function(trols)
{
    local seen = {};
    local queue = [];
    local all = [];
    foreach (trol in trols) {
        queue.append(trol);
    }
    while (queue.len() > 0) {
        local trol = queue.pop();
        all.append(trol);
        seen[trol] <- true;
        local links = Link.GetAll("AIPatrol", trol);
        local count = 0;
        foreach (link in links) {
            local dest = LinkDest(link);
            if (! seen.rawin(dest)) {
                queue.append(dest);
            }
            count += 1;
        }
    }
    return all;
}

Link_SetContainType <- function(link, type)
{
    // Type should be an eDarkContainType value.
    LinkTools.LinkSetData(link, "", type);
}

enum eFrobWhere
{
    kFrobWorld = 0,
    kFrobInv = 1,
    kFrobTool = 2,
}

enum eFrobAction
{
    kFrobActionMove = 1,
    kFrobActionScript = 2,
    kFrobActionDelete = 4,
    kFrobActionIgnore = 8,
    kFrobActionFocusScript = 16,
    kFrobActionToolCursor = 32,
    kFrobActionUseAmmo = 64,
    kFrobActionDefault = 128,
    kFrobActionDeselect = 256,
}

Object_FrobField <- function(where)
{
    if (where == eFrobWhere.kFrobTool) {
        return "Tool Action";
    } else if (where == eFrobWhere.kFrobInv) {
        return "Inv Action";
    } else {
        return "World Action";
    }
}

Object_GetFrobAction <- function(obj, where = eFrobWhere.kFrobWorld)
{
    return Property.Get(obj, "FrobInfo", Object_FrobField(where));
}

Object_SetFrobAction <- function(obj, action, where = eFrobWhere.kFrobWorld)
{
    Property.Set(obj, "FrobInfo", Object_FrobField(where), action);
}

Object_AddFrobAction <- function(obj, action, where = eFrobWhere.kFrobWorld)
{
    local frob = Object_GetFrobAction(obj, where);
    frob = frob | action;
    Object_SetFrobAction(obj, frob, where);
}

Object_RemoveFrobAction <- function(obj, action, where = eFrobWhere.kFrobWorld)
{
    local frob = Object_GetFrobAction(obj, where);
    frob = frob & ~action;
    Object_SetFrobAction(obj, frob, where);
}

Object_SetFrobInert <- function(obj, inert)
{
    local metaprop = Object.Named("FrobInert");
    local has_metaprop = Object.HasMetaProperty(obj, metaprop);
    if (inert && (! has_metaprop)) {
        Object.AddMetaProperty(obj, metaprop);
    } else if ((! inert) && has_metaprop) {
        Object.RemoveMetaProperty(obj, metaprop);
    }
}

AI_AlertLevel <- function(ai)
{
    return Property.Get(self, "AI_Alertness", "Level");
}

AI_HostileTeam <- function(team1, team2)
{
    return ((team1 != eAITeam.kAIT_Neutral)
        && (team2 != eAITeam.kAIT_Neutral)
        && (team1 != team2));
}

AI_Mode <- function(ai)
{
    return Property.Get(ai, "AI_Mode", "");
}

AI_SetIdleOrigin <- function(ai, target)
{
    local pos = Object.Position(target);
    local facing = floor(Object.Facing(target).z + 0.5).tointeger();
    Property.Set(ai, "AI_IdleOrgn", "Original Location", pos);
    Property.Set(ai, "AI_IdleOrgn", "Original Facing", facing);
}

AI_Team <- function(ai)
{
    return Property.Get(ai, "AI_Team", "");
}

class PreserveMe extends SqRootScript
{
    /* Sends "NotPreserved" to self when KOd or killed, or if harmed
       by the player. */

    function IsPlayerResponsible(damage_message)
    {
        local player = Object.Named("Player");
        local culprit = damage_message.culprit;
        for (;;) {
            if (culprit == 0) return false;
            if (culprit == player) return true;

            // Follow the culpability links to see if we find a player.
            local link = Link.GetOne(linkkind("~CulpableFor"), culprit);
            if (link == 0) {
                culprit = 0;
            } else {
                culprit = LinkDest(link);
            }
        }
    }

    function OnDamage()
    {
        if (IsPlayerResponsible(message())) {
            SendMessage(self, "NotPreserved");
        }
    }

    function OnAIModeChange()
    {
        if (message().mode == eAIMode.kAIM_Dead) {
            SendMessage(self, "NotPreserved");
        }
    }
}


class GarrettConversationActor extends SqRootScript
{
    // Put this on an conversation actor, with steps in the conversation
    // that send PlayVO("schema") messages to the actor, followed by
    // Wait with a suitable time.

    function OnPlayVO()
    {
        local schema = message().data;
        Sound.PlayVoiceOver(self, schema);
    }
}


class DoorStartsOpen extends SqRootScript
{
    // Put this on a door to have it open when the mission starts.

    function OnSim()
    {
        if (message().starting) {
            SendMessage(self, "Open");
        }
    }
}


class ContainerStartsOpen extends SqRootScript
{
    // Put this on a container to have it open when the mission starts.

    function OnSim()
    {
        if (message().starting) {
            ActReact.React("tweq_control",1.0,self,0,eTweqType.kTweqTypeJoints,eTweqDo.kTweqDoActivate);
        }
    }
}


class StartsOn extends SqRootScript
{
    // Put this on an object to send it TurnOn when the mission starts.

    function OnSim()
    {
        if (message().starting) {
            SendMessage(self, "TurnOn");
        }
    }
}

class StartsOff extends SqRootScript
{
    // Put this on a n object to send it TurnOff when the mission starts.

    function OnSim()
    {
        if (message().starting) {
            SendMessage(self, "TurnOff");
        }
    }
}

class TrapStartsOn extends SqRootScript
{
    // Put this on one of the stock Traps to send it TurnOn momentarily after
    // the mission starts. 'StartsOn' doesnt work because StdTraps ignore TurnOn
    // messages from themselves; but they _do_ accept "TurnOn" timer messages!
    function OnSim()
    {
        if (message().starting) {
            SetOneShotTimer("TurnOn", 0.01);
        }
    }

}

class TrapStartsOff extends SqRootScript
{
    // Put this on one of the stock Traps to send it TurnOff momentarily after
    // the mission starts. 'StartsOff' doesnt work because StdTraps ignore TurnOn
    // messages from themselves; but they _do_ accept "TurnOff" timer messages!
    function OnSim()
    {
        if (message().starting) {
            SetOneShotTimer("TurnOff", 0.01);
        }
    }

}

/* Sends itself TurnOff a few seconds after receiving TurnOn */
class AutoTurnOff extends SqRootScript
{
    timer = 0;

    function OnTurnOn()
    {
        // If we get multiple TurnOns before the timer fires, kill the old timer.
        if (timer != 0) {
            KillTimer(timer);
            timer = 0;
        }

        timer = SetOneShotTimer("AutoTurnOff", 6.0);
    }

    function OnTimer()
    {
        if (message().name == "AutoTurnOff") {
            SendMessage(self, "TurnOff");
            timer = 0;
        }
    }
}

/* Adds and removes "(Unconscious)" / "(Corpse)" to an AI's 'Object Name' property
   when their status changes.  If the AI's name refers to an OBJNAMES.STR entry,
   that will be read when the game starts.  To localise the status labels, add
   the 'Name_UncStatus' and 'Name_CorpseStatus' strings to OBJNAMES.STR. */
class AIStatusSuffix extends SqRootScript
{
    function UpdateSuffix()
    {
        // What is my original given name?
        local name = GetData("AIStatusName");
        if (name == "" || name == null) {
            name = Data.GetObjString(self, "objnames");
            SetData("AIStatusName", name);
        }

        // Am I dead or unconscious?
        local suffix = "";
        local mode = Property.Get(self, "AI_Mode");
        if (mode == eAIMode.kAIM_Dead) {
            local hp = Property.Get(self, "HitPoints");
            if (hp <= 0) {
                local text = Data.GetString("objnames.str", "Name_CorpseStatus");
                if (text == "") { text = "(Corpse)"; }
                suffix = " " + text;
            } else {
                local text = Data.GetString("objnames.str", "Name_UncStatus");
                if (text == "") { text = "(Unconscious)"; }
                suffix = " " + text;
            }
        }

        // Update my name property
        local prop = ("@hack: \"" + name + suffix + "\"");
        Property.SetSimple(self, "GameName", prop);
    }

    function OnSim()
    {
        if (message().starting) {
            UpdateSuffix();
        }
    }

    function OnAIModeChange()
    {
        UpdateSuffix();
    }

    function OnSlain()
    {
        UpdateSuffix();
    }
}

class LockboxFrobSound extends SqRootScript
{
    function OnFrobWorldEnd()
    {
        if (Locked.IsLocked(self)) {
            Sound.PlaySchemaAtObject(self, "locked", self);
        }
    }
}

class TrapFlipFlop extends SqRootScript
{
    /* When receiving TurnOn messages, passes on TurnOn, TurnOff, ...
       alternating. Ignores TurnOff. */
    function OnBeginScript() {
        if (! IsDataSet("LastSentOn")) {
            SetData("LastSentOn", false);
        }
    }

    function OnTurnOn() {
        local last_sent_on = GetData("LastSentOn");
        local sending_on = (! last_sent_on);
        SetData("LastSentOn", sending_on);
        local message = (sending_on ? "TurnOn" : "TurnOff");
        Link.BroadcastOnAllLinks(self, message, "ControlDevice");
    }
}

class TrapToggleExistence extends SqRootScript
{
    /*
    When receiving TurnOn, Teleport CD-linked objects to their initial
    locations; when receiving TurnOff, teleport them to <0,0,0>.
    Respects only the Invert flag of Trap Control Flags.

    (OnSim, this spawns TeleportTraps to do the dirty work, and self-destructs)
    */

    function OnSim() {
        if (message().starting) {
            // Find all the targets first, so we dont have an active link
            // query as we are creating more links, just in case.
            local targets = [];
            foreach (link in Link.GetAll("ControlDevice", self)) {
                targets.append(LinkDest(link));
            }
            // Also find everyone who wants to control us, so we can make them
            // control the teleport traps instead.
            local controllers = [];
            foreach (link in Link.GetAll("~ControlDevice", self)) {
                controllers.append(LinkDest(link));
            }
            // Get our Trap Control Flags to pass on to our children.
            local flags = 0;
            if (HasProperty("TrapFlags")) {
                flags = GetProperty("TrapFlags");
            }
            local invertedFlags = flags^TRAPF_INVERT;
            // Now create two TeleportTraps for each object we control:
            // one at its exact location, and one at the origin, and set them
            // up instead of us.
            foreach (target in targets) {
                local targetTrap = Object.Create("TeleportTrap");
                local originTrap = Object.Create("TeleportTrap");
                Property.SetSimple(targetTrap, "TrapFlags", flags);
                Property.SetSimple(originTrap, "TrapFlags", invertedFlags);
                Object.Teleport(targetTrap, vector(), vector(), target);
                Object.Teleport(originTrap, vector(), vector());
                Link.Create("ControlDevice", targetTrap, target);
                Link.Create("ControlDevice", originTrap, target);
                foreach (controller in controllers) {
                    Link.Create("ControlDevice", controller, targetTrap);
                    Link.Create("ControlDevice", controller, originTrap);
                }
            }
            // Finally, we can go away.
            Object.Destroy(self);
        }
    }
}
