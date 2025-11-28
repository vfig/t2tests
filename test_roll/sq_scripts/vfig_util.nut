/* Return a description of the obj, including its name or its archetype name. */
desc <- function(obj)
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

class DumpMessages extends SqRootScript {
    function OnMessage()
    {
        print(desc(self)+": "+message().message+" (at "+GetTime()+")");
    }
}

class DumpPhysMessages extends DumpMessages {
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg
            | ePhysScriptMsgType.kContactMsg | ePhysScriptMsgType.kEnterExitMsg
            | ePhysScriptMsgType.kFellAsleepMsg | ePhysScriptMsgType.kWokeUpMsg
            | ePhysScriptMsgType.kMadePhysMsg
            | ePhysScriptMsgType.kMadeNonPhysMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg
            | ePhysScriptMsgType.kContactMsg | ePhysScriptMsgType.kEnterExitMsg
            | ePhysScriptMsgType.kFellAsleepMsg | ePhysScriptMsgType.kWokeUpMsg
            | ePhysScriptMsgType.kMadePhysMsg
            | ePhysScriptMsgType.kMadeNonPhysMsg);
    }
}

class DebugMessage extends SqRootScript
{
    /* Shows the message in the Inventory > Long Description property when frobbed or turned on. */

    function OnTurnOn()
    {
        Activate();
    }

    function OnFrobInvBegin()
    {
        Activate();
    }

    function OnFrobWorldBegin()
    {
        Activate();
    }

    function Activate()
    {
        local text = Property.Get(self, "GameDesc", "");
        if (text != "") {
            print("MESSAGE: " + text);
            DarkUI.TextMessage(text, 0);
        }
    }
}

class DebugQuestVars extends SqRootScript
{
    //-- Utils

    function MissionPathname()
    {
        // If we had access to the Mission Pathname property from script, 
        // we wouldn't have to hardcode this. :-/
        return "miss20";
    }

    function GoalExists(num) {
        return Quest.Exists("goal_state_" + num);
    }

    function DumpGoal(num) {
        local text = "Goal " + num + ":";

        if (GoalExists(num)) {
            local goal_text = Data.GetString(MissionPathname() + "/goals", "text_" + num, "", "intrface");
            local goal_state = Quest.Get("goal_state_" + num).tointeger();
            local goal_visible = Quest.Get("goal_visible_" + num).tointeger();
            local goal_reverse = Quest.Get("goal_reverse_" + num).tointeger();
            local goal_type = Quest.Get("goal_type_" + num).tointeger();
            local goal_target = Quest.Get("goal_target_" + num).tointeger();
            local goal_target_name = Object.GetName(goal_target);
            local goal_irreversible = Quest.Get("goal_irreversible_" + num).tointeger();
            local goal_final = Quest.Get("goal_final_" + num).tointeger();
            local goal_max_diff = Quest.Get("goal_max_diff_" + num).tointeger();
            local goal_min_diff = Quest.Get("goal_min_diff_" + num).tointeger();
            local goal_loot = Quest.Get("goal_loot_" + num).tointeger();
            local goal_gold = Quest.Get("goal_gold_" + num).tointeger();
            local goal_gems = Quest.Get("goal_gems_" + num).tointeger();
            local goal_goods = Quest.Get("goal_goods_" + num).tointeger();
            local goal_special = Quest.Get("goal_special_" + num).tointeger();
            local difficulty = Quest.Get("difficulty");

            if (goal_state == 0) {
                text += " [ ]   "
            } else if (goal_state == 1) {
                text += " [DONE]"
            } else if (goal_state == 2) {
                text += " [N/A] "
            } else if (goal_state == 3) {
                text += " [FAIL]"
            }

            if (goal_visible == 0) {
                text += " (hidden)"
            }

            text += " \"" + goal_text + "\"";

            if (goal_reverse == 1) {
                text += " don't"
            }

            if (goal_type == 0) {
                text += " (scripted)"
            } else if (goal_type == 1) {
                text += " steal"
            } else if (goal_type == 2) {
                text += " kill"
            } else if (goal_type == 3) {
                text += " loot:"
            } else if (goal_type == 3) {
                text += " go to"
            }

            if (goal_type == 1 || goal_type == 2 || goal_type == 4) {
                text += " " + goal_target_name + " (" + goal_target + ")";
            } else if (goal_type == 3) {
                if (goal_gold != 0) {
                    text += " " + goal_gold + " gold;";
                }
                if (goal_gems != 0) {
                    text += " " + goal_gems + " gems;";
                }
                if (goal_goods != 0) {
                    text += " " + goal_goods + " goods;";
                }
                if (goal_special != 0) {
                    text += " " + goal_special + " special;";
                }
                if (goal_loot != 0) {
                    text += " " + goal_loot + " total;";
                }

            }

            if (goal_irreversible != 0) {
                text += " (irreversible)";
            }

            if (goal_final != 0) {
                text += " (final goal)";
            }

            local diff_names = array(3);
            diff_names[0] = "Normal";
            diff_names[1] = "Hard";
            diff_names[2] = "Expert";

            if (goal_min_diff != 0) {
                if (goal_max_diff != 0) {
                    text += " [" + diff_names[goal_min_diff] + " - " + diff_names[goal_max_diff] + "]";
                } else {
                    text += " [" + diff_names[goal_min_diff] + " - expert]";
                }
            } else if (goal_max_diff != 0) {
                    text += " [normal - " + diff_names[goal_max_diff] + "]";
            }

            if (goal_min_diff != 0 || goal_max_diff != 0) {
                text += " (currently: " + diff_names[difficulty] + ")";
            }

        } else {
            text += " does not exist.";
        }

        return text;
    }

    function DumpAllGoals() {
        local text = "";
        for (local num = 0; num < 32; num += 1) {
            if (GoalExists(num)) {
                text += DumpGoal(num) + "\n";
            }
        }
        return text;
    }

    function Display(text) {
        DarkUI.TextMessage(text);
        print(text);
    }

    function GetNumber(name)
    {
        local lastIndex;
        for (local i = name.find("_");
                i != null;
                i = name.find("_", i + 1)) {
            lastIndex = i;
        }
        if (lastIndex != null) {
            return name.slice(lastIndex + 1).tointeger();
        } else {
            return 999;
        }
    }

    function GetName(name)
    {
        local lastIndex;
        for (local i = name.find("_");
                i != null;
                i = name.find("_", i + 1)) {
            lastIndex = i;
        }
        if (lastIndex != null) {
            return name.slice(0, lastIndex);
        } else {
            return "???";
        }
    }

    //-- Messages

    function OnBeginScript()
    {
        print("DebugQuestVars on " + Object.GetName(self) + " (" + self + ") is watching all goals.");
        for (local num = 0; num < 32; num += 1) {
            if (GoalExists(num)) {
                Quest.SubscribeMsg(self, "goal_state_" + num);
                Quest.SubscribeMsg(self, "goal_visible_" + num);
            }
        }
        //Display(DumpAllGoals());
    }

    function OnEndScript()
    {
        for (local num = 0; num < 32; num += 1) {
            if (GoalExists(num)) {
                Quest.UnsubscribeMsg(self, "goal_state_" + num);
                Quest.UnsubscribeMsg(self, "goal_visible_" + num);
            }
        }
    }

    function OnQuestChange()
    {
        if (message().m_oldValue != message().m_newValue) {
            local name = GetName(message().m_pName);
            local num = GetNumber(message().m_pName);
            if (name == "goal_state") {
                Display(DumpGoal(num));
            } else {
                print(DumpGoal(num));
            }
            print("    " + message().m_pName + ": " + message().m_oldValue + " -> " + message().m_newValue);
        }
    }

    function OnTurnOn()
    {
        Display(DumpAllGoals());
    }
}

class DebugPocketStats extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            DumpAllPockets();
        }
    }

    function DumpAllPockets() {
        local contains_kind = linkkind("Contains");
        local belt_count = 0;
        local alt_count = 0;
        local dead_count = 0;
        local slink = sLink();

        local links = Link.GetAll(contains_kind);
        foreach (link  in links) {
            slink.LinkGet(link);

            // Check if it's a dead or ignored AI
            local ai_dead = false;
            local ai_null = false;
            if ((Property.Possessed(slink.source, "AI_Mode"))
                && (Property.Get(slink.source, "AI_Mode") == eAIMode.kAIM_Dead))
            {
                ai_dead = true;
            } else if ((Property.Possessed(slink.source, "AI"))
                && (Property.Get(slink.source, "AI") == "null"))
            {
                ai_null = true;
            }

            local type = LinkTools.LinkGetData(link, "");
            if (type == eDarkContainType.kContainTypeBelt) {
                if(! ai_null) {
                    if (! ai_dead) {
                        ++belt_count;
                    } else {
                        ++dead_count;
                    }
                }
                print("Belt: "
                    + (ai_dead ? "[WARNING, dead!] " : "")
                    + (ai_null ? "[ignored] " : "")
                    + Object_Description(slink.source)
                    + " -> " + Object_Description(slink.dest));
            } else if (type == eDarkContainType.kContainTypeAlt) {
                if(! ai_null) {
                    if (! ai_dead) {
                        ++alt_count;
                    } else {
                        ++dead_count;
                    }
                }
                print("Alt:  "
                    + (ai_dead ? "[WARNING, dead!] " : "")
                    + (ai_null ? "[ignored] " : "")
                    + Object_Description(slink.source)
                    + " -> " + Object_Description(slink.dest));
            }
        }

        print("Valid pockets:    " + (belt_count + alt_count));
        print("  belts:          " + belt_count);
        print("  alts:           " + alt_count);
        print("  WARNING, dead!: " + dead_count);
    }
}

class EditorOnly extends SqRootScript
{
    function OnBeginScript()
    {
        if (! IsEditor()) {
            Object.Destroy(self);
        }
    }
}

class EditorVisibleOnly extends SqRootScript
{
    function OnBeginScript()
    {
        if (! IsEditor()) {
            SetProperty("RenderType", 1);
        }
    }
}

class CheckDarkGameType extends SqRootScript
{
    // Sends TurnOn to all ControlDevice links if
    // the game is not the required game.
    function OnSim()
    {
        if (message().starting) {
            // required_game_type should be:
            //   0 = T1/TG
            //   1 = SS2
            //   2 = T2
            local required_game_type = 0;

            local game_type = GetDarkGame();
            print("Game type is " + game_type
                + ", mission requires " + required_game_type);

            if (game_type != required_game_type) {
                Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            }
        }
    }
}

class CheckNewDarkVersion extends SqRootScript
{
    // Sends TurnOn to all ControlDevice links if
    // the game is not NewDark 1.26 (or later)
    function OnSim()
    {
        if (message().starting) {
            local required_major_version = 1;
            local required_minor_version = 26;

            local major_version = int_ref();
            local minor_version = int_ref();
            Version.GetVersion(major_version, minor_version);
            print("NewDark version is " + major_version + "." + minor_version
                + ", mission requires version " + required_major_version + "." + required_minor_version);

            local bad_major_version = (major_version.tointeger() < required_major_version);
            local bad_minor_version = ((major_version.tointeger() == required_major_version)
                && (minor_version.tointeger() < required_minor_version));
            if (bad_major_version || bad_minor_version) {
                Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            }
        }
    }
}

class CheckSquirrelScript extends SqRootScript
{
    // Put this on a concrete room where the player starts, with
    // The TrigPlayerRoom script, and a ControlDevice link to
    // whatever should be activated if Squirrel scripts don't load.
    //
    // If Squirrel scripts _do_ load, this script will destroy the
    // objects pointed to by the links before they can activate.
    function OnSim()
    {
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            Object.Destroy(obj);
        }
    }
}

class EditorOnlyProcessDifficulty extends SqRootScript
{
    /*
    Place this on a single object (NOT StartingPoint), and in its
    Design Note parameters, set `Difficulty` to 0 (Normal), 1 (Hard),
    or 2 (Expert). when game mode begins, the difficulty will be
    processed accordingly.

    When running in the actual game, this script will do nothing.
    */

    function OnSim() {
        if (IsEditor() && message().starting) {
            local diff = -1;
            if ("Difficulty" in userparams()) {
                diff = userparams().Difficulty;
            }
            if (diff>=0 && diff<3) {
                if (! Quest.Exists("difficulty")) {
                    Quest.Set("difficulty", diff, eQuestDataType.kQuestDataMission);
                }
                DarkUI.TextMessage("Processing difficulty "+diff, 0x0000FF);
                Debug.Command("process_difficulty");
            } else {
                DarkUI.TextMessage(
                    "'Difficulty' param needs to be set to 0, 1, or 2 on "
                    +Object_Description(self), 0x0000FF);
            }
        }
    }
}

/* Put this on an object (i.e. the player/StartingPoint) to
spew on screen the name of each concrete room as they enter it. */
class DebugRoomSpew extends SqRootScript {
    function OnObjRoomTransit() {
        if (IsEditor()) {
            local fromRoom = message().FromObjId;
            local toRoom = message().ToObjId;
            local s;
            if (toRoom) {
                s = "Room: "+Object_Description(toRoom);
            } else {
                s = "[not in a room]";
                Sound.PlayAmbient(self, "belldinn");
            }
            print(s);
            DarkUI.TextMessage(s, 0xb40ef1, 2000.0);
        }
    }
}

/* Put this on an EditorOnly object that the player can throw
somewhere to make sounds. */
class DebugSoundMaker extends SqRootScript {
    function EnableMakingSounds(enabled) {
        local schema = "sg1a1h";
        local isMakingSounds = false;
        if (IsDataSet("IsMakingSounds")) {
            isMakingSounds = GetData("IsMakingSounds");
        }
        if (! isMakingSounds && enabled) {
            // Start:
            Sound.PlaySchemaAtObject(self, schema, self);
            SetData("IsMakingSounds", true);
        } else if (isMakingSounds && ! enabled) {
            // Stop:
            Sound.HaltSchema(self);
            SetData("IsMakingSounds", false);
        }
    }

    function EnableTimer(enabled) {
        local timer = 0;
        if (IsDataSet("RepeatTimer")) {
            timer = GetData("RepeatTimer");
        }
        if (! timer && enabled) {
            // Start:
            timer = SetOneShotTimer("MakeASound", 1.0);
            SetData("RepeatTimer", timer);
        } else if (timer && ! enabled) {
            // Stop:
            KillTimer(timer);
            ClearData("RepeatTimer");
        }
    }

    function OnTimer() {
        if (message().name=="MakeASound") {
            EnableMakingSounds(false);
            EnableMakingSounds(true);
            local timer = SetOneShotTimer("MakeASound", 1.0);
            SetData("RepeatTimer", timer);
        }
    }

    function OnBeginScript() {
        local types = (ePhysScriptMsgType.kMadePhysMsg
            | ePhysScriptMsgType.kMadeNonPhysMsg);
        Physics.SubscribeMsg(self, types);
    }

    function OnEndScript() {
        local types = (ePhysScriptMsgType.kMadePhysMsg
            | ePhysScriptMsgType.kMadeNonPhysMsg);
        Physics.UnsubscribeMsg(self, types);
    }

    function OnPhysMadePhysical() {
        EnableTimer(true);
    }

    function OnPhysMadeNonPhysical() {
        EnableTimer(false);
        EnableMakingSounds(false);
    }
}
