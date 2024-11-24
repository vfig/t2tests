/* NOTES ON MESSAGES:

    local Player has Networking.IsProxy(): FALSE
    MP Avatar has Networking.IsProxy(): TRUE
    MP Avatar NEVER receives Sim messages.

    Sim (starting): on mission start ONLY.    
    BeginScript: on game mode start; after reload
    EndScript: on game mode end; before reload
    DarkGameModeChange (resuming): on game mode start; after reload
    DarkGameModeChange (suspending): on game mode end; before reload

    Note: having mod_path point to a symlinked dir doesnt work properly,
    but having it point to a junction is fine.
 */

print("Loaded \"mpcostume.nut\"");

class MPDoll extends SqRootScript {
    function OnBeginScript() {
        // This will run both on mission start and when loading a save.
        ApplyCostume(GetCurrentCostume());
    }

    function OnFrobInvEnd() {
        // Switch to the next defined costume.
        local costume = GetCurrentCostume();
        local index = GetCostumeIndex(costume);
        if (index>=0)
            index = (index+1)%MP_AVATAR_COSTUMES.len();
        else
            index = 0;
        costume = MP_AVATAR_COSTUMES[index];
        ApplyCostume(costume);
    }

    function GetCurrentCostume() {
        // Get the current costume from the player. If there is none
        // set, check the `mp_costume` config var. If it does not
        // exist, default to the first defined costume.
        local costume = SendMessage("Player","MPGetCostume");
        if (costume==null || costume==0 || costume=="") {
            costume = MP_AVATAR_COSTUMES[0];
            if (Engine.ConfigIsDefined("mp_costume")) {
                local sref = string();
                if (Engine.ConfigGetRaw("mp_costume", sref)) {
                    costume = sref.tostring();
                }
            }
        }
        return costume;
    }

    function GetCostumeIndex(costume) {
        // Return the index of the named costume, or -1 if
        // the name is not a defined costume.
        local index = 0;
        for (local i=0; i<MP_AVATAR_COSTUMES.len(); ++i) {
            local other = MP_AVATAR_COSTUMES[i]
            if (other.tolower()==costume.tolower()) {
                return i;
            }
        }
        return -1;
    }

    function ApplyCostume(costume) {
        // Change our appearance and tell the player to change too.
        SetProperty("ModelName", "mpdo"+costume);
        SendMessage("Player", "MPSetCostume", costume);
    }
}

class MPCostumedAvatar extends SqRootScript {
    function IsRemoteAvatar() {
        return Networking.IsProxy(self);
    }

    function OnSim() {
        // Spawn a doll in our inventory for changing costume.
        if (message().starting) {
            if (! IsRemoteAvatar()) {
                local o = Object.Create("MPDoll");
                Container.Add(o, self);
            }
        }
    }

    function OnMPGetCostume() {
        // Reply with the current costume name, or null if none is set.
        if (IsDataSet("Costume")) {
            local costume = GetData("Costume");
            Reply(GetData("Costume"));
        } else {
            Reply(null);
        }
    }

    function OnMPSetCostume() {
        // Change costume to message().data (assume that it is defined),
        // and broadcast to other players that I have changed costume.
        local costume = message().data.tostring();
        SetData("Costume", costume);
        BroadcastToRemotePlayers("MPRemSetCostume", costume);
    }

    function OnMPRemSetCostume() {
        // Another player changed costume; change our proxy for them
        // to use their model.
        local from = message().from;
        local costume = message().data;
        local fromNum = Networking.ObjToPlayerNum(from);
        if (fromNum!=0) {
            Property.SetSimple(from,"ModelName","mpav"+costume);
        }
    }

    function BroadcastToRemotePlayers(message, data=null, data2=null, data3=null) {
        local myNum = Networking.MyPlayerNum();
        local playerCount = Networking.NumPlayers();
        for (local i=1; i<=playerCount; ++i) {
            if (i==myNum) continue;
            local o = Networking.PlayerNumToObj(i);
            if (o==0) continue;
            PostMessage(o, message, data, data2, data3);
        }
    }
}
