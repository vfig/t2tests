/* BIG REALISATION:
** rather than faff about with the actual in-inventory compass and making
** it go from junk to not, and whatnot -- lets have ANOTHER object that
** is also a Compass2 inheritor, that is ALWAYS junk and not dropabble, and
** simply add/remove it from inventory when necessary!
**
** (we can still have the actual actual inventory compass have an eye and
** animate, cause thats fun and creepy! but for the grab-you-by-the-collar-
** and-talk bits, almost certainly gonna be more robust with this other approach!)
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
        local o = Object.Named("MyCompass");
        //Property.SetSimple(o, "InvType", eInventoryType.kInvTypeJunk);

        // BUG 1: this *doesnt* work if the compass was already
        //      selected, but defocused (i.e. hidden)! i guess
        //      because the selection isnt actually changing :(
        // WORKAROUND: select a different object for one frame:

        // print("Workaround 1");
        // DarkUI.InvSelect(Object.Named("MyLoot"));
        // PostMessage(self, "SelectCompass", 1);

        print("Workaround 1b");
        Container.Remove(o);
        Property.SetSimple(o, "InvType", eInventoryType.kInvTypeJunk);
        SetOneShotTimer("DelayedSelfMessage", 0.001, "ReAddCompass")
        // BUG: there is a race condition in here, we could be triggering
        //      the button (or the script) again before the deselect
        //      fires! make sure to prevent that in the actual script!
        SetOneShotTimer("DelayedSelfMessage", 2.0, "DeselectCompass")
    }

    function OnSelectCompass() {
        local deselectAutomatically = (message().data==1);
        local o = Object.Named("MyCompass");
        local result = DarkUI.InvSelect(o);
        print("InvSelect("+o+"): "+result);
        if (deselectAutomatically) {
            SetOneShotTimer("DeselectCompass", 2.0);
        }
    }

    function OnDeselectCompass() {
        local o = Object.Named("MyCompass");
        Property.SetSimple(o, "InvType", eInventoryType.kInvTypeItem);

        local previousObject = GetData("PreviousSelection");
        print("previousObject: "+Object_Description(previousObject));
        if (previousObject==0
        || previousObject==o) {
            // BUG 2: if we are re-selecting the compass, we cannot dismiss
            //      it with backspace! this doesnt get you stuck--you can
            //      still scroll to seomething else, and then things work
            //      okay--but it is extremely aggravating!
            //      Note that this only happens if the compass was Selected
            //      but not focused (and in the no previousObject case)!
            // ATTEMPTED WORKAROUND: select a different object for one frame
            //      NOPE: that doesnt resolve it!
            //      (maybe a slightly longer wait -- for the 'not junk anymore'
            //      animation to finish, and then waiting a frame might work?)
            // NOTES: if only there was a script interface to Inventory::ClearSelection
            //      alas there is not. HOWEVER, Inventory is a COM interface, and
            //      i think aggregated -- so a custom script module _could_
            //      probably QueryInterface it to get a little more inventory
            //      control! maybe look into that? that might also help 

            // print("Workaround 2");
            // DarkUI.InvSelect(Object.Named("MyLoot"));
            // PostMessage(self, "SelectCompass", 0);

            // ATTEMPTED WORKAROUND part II: remove the compass and re-add it!
            // NOTE: we intentionally _prevent_ the compass concrete from
            //       inheriting LootSounds, otherwise this makes a sound.
            // NOTE: removing and re-adding on the same frame doesnt work;
            //       and removing and readding with a postmessage doesnt work;
            //       but with a very small delay _does_ work!
            //       and this workaround doesnt require us to momentarily
            //       select something else (which is visible moemntarily)
            //
            // QUERY: would this workaround also fix bug 1?
            print("Workaround 2b");
            Container.Remove(o);
            //PostMessage(self, "ReAddCompass");
            SetOneShotTimer("DelayedSelfMessage", 0.001, "ReAddCompass")
        }
        else {
            local result = DarkUI.InvSelect(previousObject);
            print("InvSelect("+o+"): "+result);
        }
    }

    function OnReAddCompass() {
        local o = Object.Named("MyCompass");
        Container.Add(o, Object.Named("Player"), 0, CTF_NONE);
        //DarkUI.InvSelect(o);
    }

    function OnTimer() {
        if (message().name=="DeselectCompass") {
            OnDeselectCompass();
        }
        else if (message().name=="DelayedSelfMessage") {
            local msg = message().data;
            print(message().name+": "+msg);
            SendMessage(self, msg);
        }
    }
}


//CapabilityControl(eDrkInvCap cap_change, eDrkInvControl control);
/*
enum eDrkInvCap
{
    kDrkInvCapCycle
    kDrkInvCapWorldFrob
    kDrkInvCapWorldFocus
    kDrkInvCapInvFrob
}

enum eDrkInvControl
{
    kDrkInvControlOn
    kDrkInvControlOff
    kDrkInvControlToggle
}
*/