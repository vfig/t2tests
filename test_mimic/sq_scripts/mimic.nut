/* EMBODIMENT TYPES:

Camera.StaticAttach
-------------------
    - cannot turn camera
    - left or right click returns
    = camera overlay forced (customizable)
    - extreme FOV forced

Camera.DynamicAttach
--------------------
    + can rotate camera freely
    - left or right click returns
    = camera overlay forced (customizable)
    - extreme FOV forced

PhysAttach
----------
    = requires target to have physics
    - can only rotate camera horizontally?
    = no overlay
    = no fov change
    - maybe problems if player is close to terrain?

*/

class PossessMe extends SqRootScript {
    function ParseVector(s) {
        local v = vector();
        local at = 0;
        local i = s.find(",", at);
        if (i == null) throw("must be a vector of 3 floats");
        v.x = (s.slice(at, i)).tofloat();
        at = i+1;
        i = s.find(",", at);
        if (i == null) throw("must be a vector of 3 floats");
        v.y = (s.slice(at, i)).tofloat();
        at = i+1;
        v.z = (s.slice(at)).tofloat();
        return v;
    }

    function GetPossessOffset() {
        local params = userparams();
        local offset = vector();
        if ("PossessOffset" in params) {
            offset = ParseVector(params.PossessOffset);
        }
        return offset;
    }

    function OnFrobWorldEnd() {
        local frobber = message().Frobber;
        if (Object.InheritsFrom(frobber, "Avatar")) {
            SendMessage(frobber, "PossessMe", GetPossessOffset());
        }
    }
}

Possess <- {
    function GetAnchor() {
        return Object.Named("PossessAnchor");
    }

    function GetWasAt() {
        return Object.Named("PossessWasAt");
    }

    function GetInventory() {
        return Object.Named("PossessInventory");
    }

    function GetFrobLeft() {
        return Object.Named("PossessFrobLeft");
    }

    function GetFrobRight() {
        return Object.Named("PossessFrobRight");
    }

    function GetGhost() {
        return Object.Named("PossessGhost");
    }

    function CreateFnords() {
        local anchor = Possess.GetAnchor();
        if (anchor==0) {
            anchor = Object.BeginCreate("fnord");
            Object.SetName(anchor, "PossessAnchor");
            Object.Teleport(anchor, vector(), vector());
            Property.Set(anchor, "PhysType", "Type", 0); // OBB
            Property.Set(anchor, "PhysType", "# Submodels", 1);
            Property.Set(anchor, "PhysDims", "Size", vector());
            Property.Set(anchor, "PhysControl", "Controls Active", 8|16); // Location|Rotation
            Property.SetSimple(anchor, "CollisionType", 0); // No collision
            Property.SetSimple(anchor, "PhysCanMant", false);
            Property.SetSimple(anchor, "PhysAIColl", false);
            Object.EndCreate(anchor);
        }
        local wasAt = Possess.GetWasAt();
        if (wasAt==0) {
            wasAt = Object.BeginCreate("fnord");
            Object.SetName(wasAt, "PossessWasAt");
            Object.EndCreate(wasAt);
        }
        local inv = Possess.GetInventory();
        if (inv==0) {
            inv = Object.BeginCreate("fnord");
            Object.SetName(inv, "PossessInventory");
            Object.EndCreate(inv);
        }
        local frobLeft = Possess.GetFrobLeft();
        if (frobLeft==0) {
            frobLeft = Object.BeginCreate("fnord");
            Object.SetName(frobLeft, "PossessFrobLeft");
            Property.Set(frobLeft, "FrobInfo", "World Action", 2|16); // Script|FocusScript
            Property.Set(frobLeft, "FrobInfo", "Inv Action", 2|16); // Script|FocusScript
            Property.Set(frobLeft, "FrobInfo", "Tool Action", 2|16); // Script|FocusScript
            Property.SetSimple(frobLeft, "InvType", 2); // Weapon
            Property.SetSimple(frobLeft, "NoDrop", true);
            Property.Set(frobLeft, "Scripts", "Script 0", "PossessFrobLeft");
            // TODO: we don't want to render it like this, except for debug, right?
            // TODO: the resource doesn't load if we only set it at runtime like
            //       this! probably need an archetype with this property set.
            Property.Set(frobLeft, "InvRendType", "Resource", "webgar3");
            Property.Set(frobLeft, "InvRendType", "Type", "Alternate Bitmap");
            Object.EndCreate(frobLeft);
        }
        local frobRight = Possess.GetFrobRight();
        if (frobRight==0) {
            frobRight = Object.BeginCreate("fnord");
            Object.SetName(frobRight, "PossessFrobRight");
            Property.Set(frobRight, "FrobInfo", "World Action", 2|16); // Script|FocusScript
            Property.Set(frobRight, "FrobInfo", "Inv Action", 2|16); // Script|FocusScript
            Property.Set(frobRight, "FrobInfo", "Tool Action", 0); // [None]
            Property.SetSimple(frobRight, "InvType", 1); // Item
            Property.SetSimple(frobRight, "NoDrop", true);
            Property.Set(frobRight, "Scripts", "Script 0", "PossessFrobRight");
            // TODO: we don't want to render it like this, except for debug, right?
            // TODO: the resource doesn't load if we only set it at runtime like
            //       this! probably need an archetype with this property set.
            Property.Set(frobRight, "InvRendType", "Resource", "zombieca");
            Property.Set(frobRight, "InvRendType", "Type", "Alternate Bitmap");
            Object.EndCreate(frobRight);
        }
        local ghost = Possess.GetGhost();
        if (ghost==0) {
            ghost = Object.BeginCreate("fnord");
            Object.SetName(ghost, "PossessGhost");
            Property.SetSimple(ghost, "RenderType", 1); // Not Rendered
            Property.SetSimple(ghost, "ModelName", "playbox");
            Object.EndCreate(ghost);
        }
    }
};

class Possessor extends SqRootScript {
    function OnBeginScript() {
        if (Object.InheritsFrom(self, "Avatar")) {
            if (! IsDataSet("IsPossessing")) {
                SetData("IsPossessing", false);
            }
            if (! IsDataSet("IsTargeting")) {
                SetData("IsTargeting", false);
            }
            if (! IsDataSet("TargetingTimer")) {
                SetData("TargetingTimer", 0);
            }
            Possess.CreateFnords();
        } else {
            // We are probably the starting point. Do nothing.
        }
    }

    function IsPossessing() {
        return (!! GetData("IsPossessing"));
    }

    function IsTargeting() {
        return (!! GetData("IsTargeting"));
    }

    function GetPossessedLink() {
        foreach (link in Link.GetAll("ScriptParams")) {
            if (LinkTools.LinkGetData(link, "")=="Possessed") {
                return link;
            }
        }
        return 0;
    }

    function GetPossessedObject() {
        local link = GetPossessedLink();
        if (link==0) return 0;
        return LinkDest(link);
    }

    function OnPossessMe() {
        if (IsPossessing()) {
            // TODO: support hopping from one possession to another?
            Reply(false);
            return;
        } else {
            local offset = message().data;
            if (offset==null) offset = vector();
            BeginPossession(message().from, offset);
        }
    }

    function OnContainer() {
        if (IsPossessing()) {
            // If we pick up anything while possessed, send it to join the
            // rest of the player inventory. We don't normally expect this
            // to happen, as we are using M-NoFrobWhilePossessed to make all
            // the things unfrobbable. But maybe you want to disable that; or
            // maybe a script would have given you items; or maybe something
            // else. Let's just be robust here, shall we?
            local inv = Possess.GetInventory();
            local frobL = Possess.GetFrobLeft();
            local frobR = Possess.GetFrobRight();
            local what = message().containee;
            if (message().event==eContainsEvent.kContainAdd
            && what!=frobL && what!=frobR) {
                Container.Add(what, inv);
            }
        }
    }

    function OnFrobLeftBegin() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobLeftEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobLeftAbort() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobRightBegin() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        BeginTargeting();
        if (! IsTargeting) {
            SetData("IsTargeting", true);
            // TODO: start raycasting every frame
        }
    }

    function OnFrobRightEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        EndTargeting(true);
    }

    function OnFrobRightAbort() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        EndTargeting(false);
    }

    function EnableLootSounds(enable) {
        // Requires 'lootsounds.nut' that defines the global EnableLootSounds()
        if (("EnableLootSounds") in getroottable()) {
            ::EnableLootSounds(enable);
        } else {
            print("Warning: global EnableLootSounds() not defined; loot sounds are going to happen.");
        }
    }

    function BeginPossession(target, offset) {
        if (IsPossessing()) {
            print("ERROR! Tried to possess when already possessing. Fix this bug!");
            return false;
        }
        if (Link.AnyExist("PhysAttach", self)) {
            print("ERROR! Tried to possess when PhysAttached. Fix this bug!");
            return false;
        }
        local anchor = Possess.GetAnchor();
        local wasAt = Possess.GetWasAt();
        local inv = Possess.GetInventory();
        local frobL = Possess.GetFrobLeft();
        local frobR = Possess.GetFrobRight();
        Object.Teleport(wasAt, vector(), vector(), self);
        Container.MoveAllContents(self, inv, CTF_NONE);
        Container.Add(frobL, self, 0, CTF_NONE);
        Container.Add(frobR, self, 0, CTF_NONE);
        // NOTE: we set IsPossessing *after* inventory transfer, so that we can
        //       safely check it in Container messages.
        SetData("IsPossessing", true);
        // Get the player's head position relative to their origin. Headbob and
        // lean will affect this a little, but we are ignoring that. The main
        // thing is to properly handle standing vs crouched difference.
        local playerHeadPos = vector();
        local ignoreFacing = vector();
        Object.CalcRelTransform(self, self, playerHeadPos, ignoreFacing, 4, 0); // RelSubPhysModel, PLAYER_HEAD
        // NOTE: The camera position apparently is not at the center of the
        //       player's head submodel. So we add in a little fudge factor
        //       to get the camera to end up right about where the offset
        //       we were supplied with would indicate.
        offset = offset+vector(0.0,0.0,playerHeadPos.z-0.75);
        local toPos = Object.ObjectToWorld(target, offset);
        local toFacing = Object.Facing(target);
        Object.Teleport(anchor, toPos, toFacing);
        // TODO: if we want a fade to black, we apparently need to start it
        //       before the teleport??? or maybe that is just a not-doing-it-
        //       via-script thing.
        Object.Teleport(self, vector(), vector(), anchor);
        Link.Create("PhysAttach", self, anchor);
        // NOTE: If the anchor the player is PhysAttached to is stationary,
        //       then the player can only turn the camera horizontally, not
        //       vertically. It makes no sense, but that is what happens.
        //       To work around this, we need to control the anchor's velocity
        //       with a nonzero value; but controlling velocity disables
        //       location controls. So we make sure the anchor has no gravity,
        //       so it won't fall; we control its velocity with a small value
        //       that is nonzero so the camera works, but because the value is
        //       less than 1, it doesnt end up actually moving? Also weird,
        //       but it works for us.
        Physics.SetGravity(anchor, 0.0);
        Physics.ControlVelocity(anchor, vector(0,0,0.1));
        // And keep track of what we are possessing.
        local link = Link.Create("ScriptParams", self, target);
        LinkTools.LinkSetData(link, "", "Possessed");
        // NOTE: We prevent frobbing most objects while possessed by generously
        //       adding this metaproperty to all physical objects. This won't
        //       work for any objects in e.g. the fnord or SFX trees have been
        //       made frobbable; and it won't work for concrete objects with
        //       a direct FrobInfo property on them making them frobbable.
        //       Those must be avoided when using this script.
        // NOTE: The PossessFrobs are both fnords *and* have a direct FrobInfo
        //       property, so they will be unaffected, as they need to be.
        // NOTE: If we only need right-frob, then we can change PossessFrobRight
        //       to be a junk item, because *nothing* can be frobbed while
        //       holding a junk item.
        Object.AddMetaPropertyToMany("M-NoFrobWhilePossessed", "@physical");

        // TEMP: we don't have a way to manually detach yet, so automate it.
        //SetOneShotTimer("TempDetach", 5.0);
    }

    function EndPossession() {
        if (! IsPossessing()) {
            print("ERROR! Tried to unpossess when not possessing. Fix this bug!");
            return false;
        }
        EndTargeting(false);
        // NOTE: we must clear IsPossessing *before* inventory restoration, so
        //       that we won't react to the Container messages.
        SetData("IsPossessing", false);
        local anchor = Possess.GetAnchor();
        local wasAt = Possess.GetWasAt();
        local inv = Possess.GetInventory();
        local frobL = Possess.GetFrobLeft();
        local frobR = Possess.GetFrobRight();
        // Disconnect from the anchor.
        local link = Link.GetOne("PhysAttach", self, anchor);
        if (link==0) {
            print("ERROR! Unpossessed when not PhysAttached. Fix this bug!");
        }
        Link.Destroy(link);
        // Disconnect from the possessed target.
        link = GetPossessedLink();
        if (link==0) {
            print("ERROR! Unpossessed with no ScriptParams('Possessed') link. Fix this bug!");
        }
        Link.Destroy(link);
        // Restore player position.
        Object.Teleport(self, vector(), vector(), wasAt);
        // Restore inventory, setting the global flag to prevent loot sounds.
        EnableLootSounds(false);
        Container.Remove(frobL, self);
        Container.Remove(frobR, self);
        // TODO: will need to suppress loot sounds... maybe by making a custom
        //       squirrel LootSounds to use in preference to gen's?
        Container.MoveAllContents(inv, self, CTF_NONE);
        EnableLootSounds(true);
        // Park the anchor back at the origin ready for next time.
        Physics.StopControlVelocity(anchor);
        Object.Teleport(anchor, vector(), vector());
        Physics.ControlCurrentPosition(anchor);
        // Restore frobs.
        Object.RemoveMetaPropertyFromMany("M-NoFrobWhilePossessed", "@physical");
    }

    function BeginTargeting() {
        if (IsTargeting()) return false;
        SetData("IsTargeting", true);
        EnableTargetingTimer(true);
        local ghost = Possess.GetGhost();
        Property.SetSimple(ghost, "RenderType", 2); // Unlit
    }

    function EndTargeting(commit) {
        if (! IsTargeting()) return false;
        SetData("IsTargeting", false);
        EnableTargetingTimer(false);
        local ghost = Possess.GetGhost();
        Property.SetSimple(ghost, "RenderType", 1); // Not Rendered
        if (commit) {
            // TODO: need to handle moving the player to the targeted position
            //       (if there is a valid one)!
            EndPossession();
            return true;
        } else {
            return false;
        }
    }

    function DoTargeting() {
        // NOTE: Camera coordinates for CameraToWorld are x-forward, z-up.
        const max_distance = 20.0;
        local from = Camera.GetPosition();
        local to = Camera.CameraToWorld(vector(max_distance,0.0,0.0));

        local hit_object = object();
        local hit_location = vector();
        local hit = Engine.ObjRaycast(from, to, hit_location, hit_object,
            0,          // Always find the nearest object, not just line-of-sight.
            0x2,        // Include meshes but ignore invisible objects.
            "Player",               // Ignore the player.
            Possess.GetGhost());    // Ignore the ghost.
        // TODO: if the hit is GetPossessedObject(), we need to disregard that!
        // TODO: if the hit has no physics, then what? redo the raycast ignoring
        //       it too?? particles? decals? this is maybe awkward...
        local msg;
        if (hit==0) {
            msg = "no hit";
        } else {
            // 1 for terrain, 2 for an object, 3 for mesh object. For return
            // types 2 and 3, the hit object will be returned in 'hit_object'.
            msg = "hit type "+hit+", objid "+hit_object+" name:"+Object.GetName(hit_object.tointeger());
        }
        DarkUI.TextMessage(msg, 0, 100);

        local ghost = Possess.GetGhost();
        Object.Teleport(ghost, hit_location, vector());
    }

    function EnableTargetingTimer(enable) {
        local timer = GetData("TargetingTimer");
        if (enable && timer==0) {
            timer = SetOneShotTimer("DoTargeting", 0.030);
            SetData("TargetingTimer", timer);
        }
        if (!enable && timer!=0) {
            KillTimer(timer);
            SetData("TargetingTimer", 0);
        }
    }

    function OnTimer() {
        if (message().name=="TempDetach") {
            EndPossession();
            return;
        }
        if (message().name=="DoTargeting") {
            SetData("TargetingTimer", 0);
            EnableTargetingTimer(true);
            DoTargeting();
            return;
        }
    }
}

// TODO: there is a whole bunch of fiddly state management needed if we are going
//       to have begin/end frobs -- which i would like in order to "aim" at a
//       position to emerge at... at least thats the idea right now. but if
//       frobs are underway, clearing weapon/item cancels then without a cancel
//       message (unless...? is that when message().Abort is true??)

class PossessFrobLeft extends SqRootScript {
    function OnContained() {
        // Make sure we are selected immediately.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        if (message().event==eContainsEvent.kContainAdd) {
            DarkUI.InvSelect(self);
        }
    }

    function OnFrobWorldBegin() {
        // Player left-clicked while possessed.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobWorldEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobInvBegin() {
        // Player left-clicked while possessed.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        if (message().Abort) {
            SendMessage("Player", "FrobLeftAbort");
        } else {
            SendMessage("Player", "FrobLeftBegin");
        }
    }

    function OnFrobInvEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        SendMessage("Player", "FrobLeftEnd");
    }

    function OnFrobToolBegin() {
        // Player left-clicked while possessed and looking at a frobbable.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobToolEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnInvDeSelect() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        // Prevent from being deselected in inventory.
        // NOTE: neither DarkUI.InvSelect(self) nor the inv_select command works
        //       to prevent the weapon from being deselected! So we post a
        //       message to force a reselection next frame.
        PostMessage(self, "ForceReselect");
    }

    function OnForceReselect() {
        DarkUI.InvSelect(self);
    }

    function OnMessage() {
        // TEMP: print all other messages we might need to handle.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
}

class PossessFrobRight extends SqRootScript {
    function OnContained() {
        // Make sure we are selected immediately.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        if (message().event==eContainsEvent.kContainAdd) {
            DarkUI.InvSelect(self);
        }
    }

    function OnFrobToolBegin() {
        // TODO: see if we have a bug right-frobbing while looking at another
        //       object?
        //       enabling Script+FocusScript for Tool frobs isn't a whole solution,
        //       as it makes the item do the move-to-center behaviour, that we
        //       do *not* want.
        //       fallback workaround if needed: when becoming possessed, we mass-
        //       add a "NoFrobWhenPossessed" metaprop to all non-embodyable objects?
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobToolEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobInvBegin() {
        // NOTE: if we detach while the button is held, we get a
        //       FrobInvBegin message when the button is released,
        //       instead of a FrobInvEnd!
        // TODO: investigate if the same is true for FrobWorld and PossessFrobLeft
        // TODO: is that when message().Abort is true?
        // TODO: handle that, if detach is forced and not happening
        //       as a result of clicks. e.g., just ignore all frob messages when
        //       player is not possessed.
        print("right inv");
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        if (message().Abort) {
            SendMessage("Player", "FrobRightAbort");
        } else {
            SendMessage("Player", "FrobRightBegin");
        }
    }

    function OnFrobInvEnd() {
        print("right inv");
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        local player = Object.Named("Player");
        SendMessage("Player", "FrobRightEnd");
    }

    function OnInvDeSelect() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        // Prevent from being deselected in inventory.
        // NOTE: neither DarkUI.InvSelect(self) nor the inv_select command works
        //       to prevent the weapon from being deselected! So we post a
        //       message to force a reselection next frame.
        PostMessage(self, "ForceReselect");
    }

    function OnForceReselect() {
        DarkUI.InvSelect(self);
    }

    function OnInvDeFocus() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        // Prevent from timing out/being cleared in inventory.
        if (true) {
            print("TEMP: prevent timing out/deselection");
            // NOTE: Using DarkUI.InvSelect(self) doesn't work to refresh the
            //       PossessFrobRight; but usinv inv_select *does* work:
            Debug.Command("inv_select "+Object.GetName(self));
        }
    }

    function OnMessage() {
        // TEMP: print all other messages we might need to handle.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
}

class DebugMessages extends SqRootScript {
    function OnMessage() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }
}
