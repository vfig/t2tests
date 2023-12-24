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

class Mimic extends SqRootScript {
    function BeginEmbodiment() {
        // local f = float_ref();
        // local i = int_ref();
        // local ok = DarkGame.ConfigGetFloat("fov", f);
        // print("fov (float): "+f.tofloat()+" ok:"+ok);
        // local ok = DarkGame.ConfigGetInt("fov", i);
        // print("fov (int): "+f.tointeger()+" ok:"+ok);
        // local fov = DarkGame.BindingGetFloat("fov");
        // print("fov (binding): "+fov);

        local player = Object.Named("Player");
        local anchor = Object.Named("PlayerAnchor");
        local inv = Object.Named("PlayerInv");
        local wasAt = Object.Named("PlayerWasAt");
        local detachorL = Object.Named("PlayerDetachorLeft");
        local detachorR = Object.Named("PlayerDetachorRight");
        // TODO: if inv or wasAt do not exist, spawn them as fnords?
        //       if spawning anchor, it has specific phys needs.
        if (Link.AnyExist("PhysAttach", player)) {
            // If the player is attached, it means we are embodied already.
            return false;
        }
        Object.Teleport(wasAt, vector(), vector(), player);
        Container.MoveAllContents(player, inv, CTF_NONE);
        Container.Add(detachorL, player, 0, CTF_NONE);
        Container.Add(detachorR, player, 0, CTF_NONE);
        local targetFacing = Object.Facing(player);
        // Rotate facing 180 so player is looking back to where they came from:
        local z = targetFacing.z + 180.0;
        if (z>=360.0) z -= 360.0;
        targetFacing.z = z;
        // TODO: is that good? do we want instead to aim at... where?
        local targetPos = Object.Position(self) + vector(0.0,0.0,2.0);
        Object.Teleport(anchor, targetPos, targetFacing);
        // TODO: if we want a fade to black, we apparently need to start it
        //       before the teleport??? or maybe that is just a not-doing-it-
        //       via-script thing.
        Object.Teleport(player, vector(), vector(), anchor);
        Link.Create("PhysAttach", player, anchor);
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

        // TEMP: we don't have a way to manually detach yet, so automate it.
        SetOneShotTimer("TempDetach", 25.0);
    }

    function EndEmbodiment() {
        local player = Object.Named("Player");
        local anchor = Object.Named("PlayerAnchor");
        local inv = Object.Named("PlayerInv");
        local wasAt = Object.Named("PlayerWasAt");
        local detachorL = Object.Named("PlayerDetachorLeft");
        local detachorR = Object.Named("PlayerDetachorRight");
        local link = Link.GetOne("PhysAttach", player, anchor);
        if (link==0) {
            // If the player is not attached to us, why are we even here?
            return false;
        }
        Link.Destroy(link);
        Object.Teleport(player, vector(), vector(), wasAt);
        Container.Remove(detachorL, player);
        Container.Remove(detachorR, player);
        Container.MoveAllContents(inv, player, CTF_NONE);
        // Park the anchor back at the origin ready for next time.
        Physics.StopControlVelocity(anchor);
        Object.Teleport(anchor, vector(), vector());
        Physics.ControlCurrentPosition(anchor);
    }

    function OnFrobWorldEnd() {
        //Camera.DynamicAttach(self);
        BeginEmbodiment();
    }

    function OnTimer() {
        if (message().name=="TempDetach") {
            EndEmbodiment();
        }
    }
}

// TODO: there is a whole bunch of fiddly state management needed if we are going
//       to have begin/end frobs -- which i would like in order to "aim" at a
//       position to emerge at... at least thats the idea right now. but if
//       frobs are underway, clearing weapon/item cancels then without a cancel
//       message (unless...? is that when message().Abort is true??)

class DetachorLeft extends SqRootScript {
    function OnContained() {
        // Make sure we are selected immediately.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        if (message().event==eContainsEvent.kContainAdd) {
            DarkUI.InvSelect(self);
        }
    }

    function OnFrobWorldBegin() {
        // Player left-clicked while embodied.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobWorldEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobToolBegin() {
        // Player left-clicked while embodied and looking at a frobbable.
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

class DetachorRight extends SqRootScript {
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
        //       fallback workaround if needed: when becoming embodied, we mass-
        //       add a "NoFrobWhenEmbodied" metaprop to all non-embodyable objects?
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobToolEnd() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobInvBegin() {
        // NOTE: if we detach while the button is held, we get a
        //       FrobInvBegin message when the button is released,
        //       instead of a FrobInvEnd!
        // TODO: investigate if the same is true for FrobWorld and DetachorLeft
        // TODO: is that when message().Abort is true?
        // TODO: handle that, if detach is forced and not happening
        //       as a result of clicks. e.g., just ignore all frob messages when
        //       player is not embodied.
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
    }

    function OnFrobInvEnd() {
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

    function OnInvDeFocus() {
        print(GetTime()+": "+Object.GetName(self)+" ("+self+"): "+message().message);
        // Prevent from timing out/being cleared in inventory.
        if (true) {
            print("TEMP: prevent timing out/deselection");
            // NOTE: Using DarkUI.InvSelect(self) doesn't work to refresh the
            //       DetachorRight; but usinv inv_select *does* work:
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
