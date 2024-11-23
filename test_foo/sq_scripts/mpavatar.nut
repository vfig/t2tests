AVATAR_MODELS <- [
    "garrett",
    "basso",
    "haunt01",
];

class MPDoll extends SqRootScript {
    function OnFrobInvEnd() {
        // TODO: this object should change its model to match the one the
        //       player now has. but inventory objects have to be in obj/
        //       and so we will need one for each mesh avatar that we offer,
        //       it seems.
        // TODO: having this be local-only might fuck its state on save/load?
        local model = IsDataSet("model")? GetData("model") : "garrett";
        local currentIndex = -1;
        for (local i=0; i<AVATAR_MODELS.len(); ++i) {
            local otherModel = AVATAR_MODELS[i]
            if (otherModel.tolower()==model.tolower()) {
                currentIndex = i;
                break;
            }
        }
        ++currentIndex;
        if (currentIndex>=AVATAR_MODELS.len()) {
            currentIndex = 0;
        }
        local newModel = AVATAR_MODELS[currentIndex];
        SetData("model", newModel);
        print("Should change model to "+newModel);
        SendMessage("Player", "SetAvatarModel", newModel);
    }
}

class MPChangeAvatar extends SqRootScript {
    function OnBeginScript() {
        print("MPChangeAvatar on "+self+" - "+message().message);
        local mparch = Object.Named("MP Avatar");
        if (mparch==0) {
            printui("ERROR: cannot find 'MP Avatar'.");
            return;
        }
        if (Object.HasMetaProperty(mparch, "M-MPChangeAvatar")) {
            printui("OK: 'MP Avatar' has our metaprop.");
        }

        if (Object.InheritsFrom(self, mparch)) {
            // We are a remote avatar.
        } else {
            // We are the local player.
            // We can't create the doll immediately because we happen to be in
            // a BeginCreateObject() context, and they don't like being nested!
            // So we delay for a frame.
            PostMessage(self, "MPCreateDoll");
        }
    }

    function OnSim() {
        print("MPChangeAvatar on "+self+" - "+message().message);
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

    function BroadcastToRemotePlayers(message, data, data2, data3) {
        local myNum = Networking.MyPlayerNum();
        local playerCount = Networking.NumPlayers();
        for (local i=1; i<=playerCount; ++i) {
            if (i==myNum) continue;
            local o = Networking.PlayerNumToObj(i);
            if (o==0) continue;
            PostMessage(o, message, data, data2, data3);
        }
    }

    function OnMPCreateDoll() {
        print(self+" "+message().message+": "+message().data+", "+message().data2);
        local o = Object.Create("MPDoll");
        Container.Add(o, self);
    }

    function OnSetAvatarModel() {
        print(self+" "+message().message+": "+message().data+", "+message().data2);
        local model = message().data;
        SetData("MPModel", model);
        BroadcastToRemotePlayers("MPChangedModel", self, model, null);
    }

    function OnMPChangedModel() {
        print(self+" "+message().message+": "+message().data+", "+message().data2);
        local model = message().data2;
        local from = message().from;
        local fromNum = Networking.ObjToPlayerNum(from);
        if (fromNum!=0) {
            Property.SetSimple(from,"ModelName",model);
        }
    }

    // YES! This works!!
    function OnHello() {
        local from = message().data;
        local s = "Hello from "+from+"! ("+message().from+")";
        DarkUI.TextMessage(s, 254);
        print(s);
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
        printobj("M-MPChangeAvatar");
    }
}
