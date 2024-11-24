/* NOTES ON MESSAGES:

    local Player has Networking.IsProxy(): FALSE
    MP Avatar has Networking.IsProxy(): TRUE
    MP Avatar NEVER receives Sim messages.

    Sim (starting): on mission start ONLY.    
    BeginScript: on game mode start; after reload
    EndScript: on game mode end; before reload
    DarkGameModeChange (resuming): on game mode start; after reload
    DarkGameModeChange (suspending): on game mode end; before reload
 */

class MPDoll extends SqRootScript {
    function OnMessage() {
        // TEMP: log what messages we get on save/load/die/respawn.
        print("[:: MPDoll "+self+": "+message().message+" ::]");
    }

    function OnBeginScript() {
        ApplyCostume(GetCurrentCostume());
    }

    function OnFrobInvEnd() {
        // TODO: having this be local-only might fuck its state on save/load?
        //       but: it shouldnt be _storing_ any state!
        print("---- Change costume ------------------")
        local costume = GetCurrentCostume();
        local index = GetCostumeIndex(costume);
        print("  current costume:"+costume+" ("+index+")");
        index = (index+1)%MP_AVATAR_COSTUMES.len();
        costume = MP_AVATAR_COSTUMES[index];
        print("  new costume:"+costume+" ("+index+")");
        ApplyCostume(costume);
    }

    function GetCurrentCostume() {
        local costume = SendMessage("Player","MPGetCostume");
        print("  Player returned: <"+((costume==null)?"null":costume.tostring())+">");
        if (costume==null || costume==0 || costume=="") {
            costume = MP_AVATAR_COSTUMES[0];
            if (Engine.ConfigIsDefined("mp_costume")) {
                local sref = string();
                if (Engine.ConfigGetRaw("mp_costume", sref)) {
                    costume = sref.tostring();
                    print("...default costume from config: "+costume);
                }
            }
            print("  defaulting to : <"+costume+">");
        }
        return costume;
    }

    function GetCostumeIndex(costume) {
        local index = 0;
        for (local i=0; i<MP_AVATAR_COSTUMES.len(); ++i) {
            local other = MP_AVATAR_COSTUMES[i]
            if (other.tolower()==costume.tolower()) {
                index = i;
                break;
            }
        }
        return index;
    }

    function ApplyCostume(costume) {
        // TODO: probably dont change our model until told to by the Player,
        //       or something - thinking about reloads, and/or inventory menus.
        print("...set ModelName: "+"mpdo"+costume);
        SetProperty("ModelName", "mpdo"+costume);
        SendMessage("Player", "MPSetCostume", costume);
    }
}

class MPCostumedAvatar extends SqRootScript {
    function OnMessage() {
        // TEMP: log what messages we get on save/load/die/respawn.
        print("[:: MPCostumedAvatar "+self+": "+message().message+" ::]");
    }

    function IsRemoteAvatar() {
        return Networking.IsProxy(self);
        // // TEMP - because there might be a better way than inheriting MP Avatar.
        // print("##### self:"+self);
        // print("#####   PlayerName:"+Networking.GetPlayerName(Networking.ObjToPlayerNum(self)));
        // print("#####   HostedHere:"+Networking.HostedHere(self));
        // print("#####   IsProxy:"+Networking.IsProxy(self));
        // print("#####   LocalOnly:"+Networking.LocalOnly(self));
        // print("#####   Owner:"+Networking.Owner(self));
        // print("#####   Is MyPlayerNum:"+(Networking.ObjToPlayerNum(self)==Networking.MyPlayerNum()));
        //
        // local mparch = Object.Named("MP Avatar");
        // if (mparch==0) return false;
        // return (Object.InheritsFrom(self, mparch));
    }

    function OnSim() {
        print("[:: MPCostumedAvatar "+self+": "+message().message+" ::]");

        if (message().starting) {
            if (! IsRemoteAvatar()) {
                // Spawn a doll for changing costume.
                local o = Object.Create("MPDoll");
                Container.Add(o, self);
            }
        }
    }

    function OnMPGetCostume() {
        print("[:: MPCostumedAvatar "+self+": "+message().message+" ::]");
        if (IsDataSet("Costume")) {
            local costume = GetData("Costume");
            print("  on "+self+": costume scriptvar: '"+costume+"'");
            Reply(GetData("Costume"));
        } else {
            print("  on "+self+": costume scriptvar is not set.");
            Reply(null);
        }
    }

    function OnMPSetCostume() {
        print("[:: MPCostumedAvatar "+self+": "+message().message+"("+message().data+") ::]");
        local costume = message().data.tostring();
        SetData("Costume", costume);
        print("  on "+self+": set costume scriptvar to <"+costume+">");
        //local myNum = Networking.MyPlayerNum();
        BroadcastToRemotePlayers("MPRemSetCostume", self, costume);
    }

    function OnMPRemSetCostume() {
        print("[:: MPCostumedAvatar "+self+": "+message().message+"("+message().data+","+message().data2+") ::]");
        local from = message().from;
        local costume = message().data2;
        local fromNum = Networking.ObjToPlayerNum(from);
        if (fromNum!=0) {
            print("...set ModelName on "+from+": "+"mpav"+costume);
            Property.SetSimple(from,"ModelName","mpav"+costume);
        }
    }

/*
    function OnSim() {
        print("[:: MPCostumedAvatar "+self+": "+message().message+" ::]");

        if (message().starting) {
            local myNum = Networking.MyPlayerNum();
            local myName = Networking.GetPlayerName(self);
            for (local i=0; i<=4; ++i) {
                if (i==myNum) continue;
                local o = Networking.PlayerNumToObj(i);
                if (o==0) continue;
                print("Sending hello to Player "+i+" ("+o+")");
                PostMessage(o, "Hello", myName);
            }
        }
    }
*/

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

class DebugShit extends SqRootScript {
    function printobj(name) {
        local o = Object.Named(name);
        print(name+": "+o);
    }

    function OnSim() {
        printobj("Player");
        printobj("Avatar");
        printobj("MP Avatar");
        printobj("M-MPCostumedAvatar");
    }
}
