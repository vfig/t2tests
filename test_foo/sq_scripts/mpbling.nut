print("Loaded \"mpbling.nut\"");

BLINGDEX <- null;

class MPSetBling extends SqRootScript {
    function OnBeginScript() {
        // This will run both on mission start and when loading a save.
        ApplyBling(GetCurrentBling());
    }

    function OnFrobInvEnd() {
        // Switch to the next defined bling.
        local bling = GetCurrentBling();
        local index = GetBlingIndex(bling);
        if (index<0) {
            bling = BLINGDEX[0];
        } else if (index>=0 && index<BLINGDEX.len()-1) {
            bling = BLINGDEX[index+1];
        } else {
            bling = "none";
        }
        ApplyBling(bling);
    }

    function GetCurrentBling() {
        // Get the current bling from the player. If there is none
        // set, check the `mp_bling` config var. If it does not
        // exist, default to no bling.
        local bling = SendMessage("Player","MPGetBling");
        if (bling==null || bling==0 || bling=="") {
            bling = "none";
            if (Engine.ConfigIsDefined("mp_bling")) {
                local sref = string();
                if (Engine.ConfigGetRaw("mp_bling", sref)) {
                    bling = sref.tostring();
                }
            }
        }
        return bling;
    }

    function GetBlingIndex(bling) {
        // Return the index of the named bling, or -1 if
        // the name is not a defined bling.
        bling = bling;
        local index = BLINGDEX.find(bling.tolower());
        if (index==null) return -1;
        return index;
    }

    function ApplyBling(bling) {
        // Change our name and appearance; tell the player to change too.
        local arch = Object.Archetype(self);
        local template = Property.Get(arch, "GameName");
        local name = format(template, bling);
        SetProperty("GameName", name);
        SetProperty("ModelName", "mpat"+bling);
        SendMessage("Player", "MPSetBling", bling);
    }
}

class MPBlingedAvatar extends SqRootScript {
    function IsRemoteAvatar() {
        return Networking.IsProxy(self);
    }

    function OnBeginScript() {
        // Fill out the blingdex ready for index lookups.
        if (BLINGDEX==null) {
            BLINGDEX = [];
            foreach (k,_ in MP_AVATAR_BLINGS) {
                BLINGDEX.append(k.tolower());
            }
            BLINGDEX.sort();
        }
    }

    function OnSim() {
        // Spawn an item in our inventory for changing bling.
        if (message().starting) {
            if (! IsRemoteAvatar()) {
                local o = Object.Create("MPSetBling");
                Container.Add(o, self);
            }
        }
    }

    function OnMPGetBling() {
        // Reply with the current bling name, or null if none is set.
        if (IsDataSet("Bling")) {
            local bling = GetData("Bling");
            Reply(GetData("Bling"));
        } else {
            Reply(null);
        }
    }

    function OnMPSetBling() {
        // Change bling to message().data (assume that it is defined),
        // and broadcast to other players that I have changed bling.
        local bling = message().data.tostring();
        SetData("Bling", bling);
        BroadcastToRemotePlayers("MPRemSetBling", bling);
    }

    function OnMPRemSetBling() {
        // Another player changed bling; change our proxy for them
        // to use their model.
        local from = message().from;
        local bling = message().data;
        local fromNum = Networking.ObjToPlayerNum(from);
        if (fromNum!=0) {
            AttachBling(from,bling);
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

    function AttachBling(target,bling) {
        local arch = Object.Named("MPBling");
        if (arch==0) return;
        // Destroy the old bling (if any)
        foreach (link in Link.GetAll("~DetailAttachement", target)) {
            if (Object.InheritsFrom(LinkDest(link), arch)) {
                Link.Destroy(link);
                break;
            }
        }
        // Spawn a new bling (if there is one)
        if (bling=="none") return;
        local blingProps = MP_AVATAR_BLINGS[bling];
        local blingObj = Object.BeginCreate(arch);
        Property.SetSimple(blingObj,"ModelName","mpat"+bling);
        Object.Teleport(blingObj, vector(), vector(), target);
        foreach (prop in ["ModelName", "Scale"]) {
            if (prop in blingProps) {
                Property.Add(blingObj, prop);
                local values = blingProps[prop];
                for (local i=0; i<values.len(); i+=2) {
                    local f = values[i];
                    local v = values[i+1];
                    Property.Set(blingObj, prop, f, v);
                }
            }
        }
        Object.EndCreate(blingObj);
        local blingLink = Link.Create("DetailAttachement", blingObj, target);
        if ("DetailAttachement" in blingProps) {
            print("Detailattaching...");
            local values = blingProps["DetailAttachement"];
            for (local i=0; i<values.len(); i+=2) {
                local f = values[i];
                local v = values[i+1];
                // For whatever reason, "rel rot" in properties and
                // in the link itself are in different orders! :(
                if (f=="rel rot") {
                    print("hacking rot");
                    v = vector(v.z,v.y,v.x);
                }
                print("  "+f+": "+v);
                LinkTools.LinkSetData(blingLink, f, v);
                print("  (readback: "+LinkTools.LinkGetData(blingLink, f)+")");
            }
        }
    }
}
