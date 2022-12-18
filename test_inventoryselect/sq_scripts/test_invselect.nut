/* BIG REALISATION:
** rather than faff about with the actual in-inventory compass and making
** it go from junk to not, and whatnot -- lets have ANOTHER object that
** is also a Compass2 inheritor, that is ALWAYS junk and not dropabble, and
** simply add/remove it from inventory when necessary!
**
** (we can still have the actual actual inventory compass have an eye and
** animate, cause thats fun and creepy! but for the grab-you-by-the-collar-
** and-talk bits, almost certainly gonna be more robust with this other approach!)
**
** SEE BELOW: tried it and it works *beautifully*!
*/

class DumpMessages extends SqRootScript {
    function OnMessage() {
        print("Player <- "+message().message);
    }

    function OnContainer() {
        local eventStrings = [
            "kContainQueryAdd",
            "kContainQueryCombine",
            "kContainAdd",
            "kContainRemove",
            "kContainCombine",
        ];

        print("Player <- "+message().message
            +" event:"+eventStrings[message().event]
            +" containee:"+Object_Description(message().containee));
    }
}

class PrintFocusMessages extends SqRootScript {
    // NOTE: player gets a Container message when picking up *anything*
    //       we can use this to add a MetaProperty with the 'track Inv*'
    //       script (so we can tell when other objects are selected/defocused).
    // NOTE: if the object being picked up is combined (e.g. loot, or an
    //       existing stack exists), then message().containee is the existing
    //       inventory object! for our purposes, this is ideal.

    function OnInvSelect() {
        print(Object_Description(self)+" ("+self+"): "+message().message);
    }
    function OnInvDeselect() {
        print(Object_Description(self)+" ("+self+"): "+message().message);
    }
    function OnInvFocus() {
        print(Object_Description(self)+" ("+self+"): "+message().message);
    }
    function OnInvDeFocus() {
        print(Object_Description(self)+" ("+self+"): "+message().message);
    }
}

class DumpInventoryInfo extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("DumpInventoryInfo", 2.0);
        }
    }

    function OnTimer() {
        if (message().name=="DumpInventoryInfo") {
            local item = DarkUI.InvItem();
            local weapon = DarkUI.InvWeapon();
            print("#INV: item:"+Object_Description(item)+", weapon:"+Object_Description(weapon));
            SetOneShotTimer("DumpInventoryInfo", 2.0);
        }
    }
}

class ForceSelectCompass extends SqRootScript {
    function OnTurnOn() {
        local previousObject = DarkUI.InvItem();
        SetData("PreviousSelection", previousObject);
        local compass = Object.Named("AttentionCompass");
        Container.Add(compass, Object.Named("Player"), 0, CTF_NONE);
        SetOneShotTimer("DelayedSelfMessage", 2.0, "DeselectCompass")
    }

    function OnTimer() {
        if (message().name=="DelayedSelfMessage") {
            SendMessage(self, message().data);
        }
    }

    function OnDeselectCompass() {
        local compass = Object.Named("AttentionCompass");
        Container.Remove(compass);
        // TODO: also teleport the compass elsewhere so its not left
        //       hovering where the player was, lol.
        local previousObject = GetData("PreviousSelection");
        ClearData("PreviousSelection");
        DarkUI.InvSelect(previousObject);
    }
}
