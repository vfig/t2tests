/*  The Witch's Head: you become embodied in it when you throw it, and when it
    lands, you end up standing there.

    rough outline:

    when thrown:
     -> attach camera
        teleport player to specific blue room
    when landing:
      * check if theres room for the player
        if so:
            play success feedback sound + effect
          * teleport player there
          * move witch's head to inventory
        if not:
            play failure feedback sound + effect
            teleport player back to original location
          * move witch's head to inventory
*/
/*
    Camera modes:

        + desirable
        = acceptable / can be worked around
        - undesirable
        x showstopper

    VIEW_CAM:
        to achieve: StaticAttach() on a physical object
      + player: frozen
      - mouselook: none
      - sound: from player location
      x effects: fade-in/fade-out
      = fov: wide

    REMOTE_CAM:
        to achieve: DynamicAttach() on a physical object
      + player: frozen
      + mouselook: full
      - sound: from player location
      x effects: fade-in/fade-out
      = fov: wide
        note: camera facing is weird (see adjustment in dual/translocator.nut)

    OBJ_ATTACH:
        to achieve: StaticAttach() or DynamicAttach() on an non-physical object
      = player: can still move
      - mouselook: none
      + sound: from camera-attached-object location
      + effects: none
      = fov: default

    CONCLUSION: force OBJ_ATTACH mode, and live with no mouselook.
*/

const DEBUG_PHYSICS = false;
class ToolWitchesHead extends SqRootScript
{
    function OnSim() {
        print("WitchesHead: " + message().message);
        if (message().starting) {
            Physics.SubscribeMsg(self, ePhysScriptMsgType.kFellAsleepMsg);

            if (DEBUG_PHYSICS) {
                Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
                Physics.SubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
                Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
                Physics.SubscribeMsg(self, ePhysScriptMsgType.kWokeUpMsg);
                Physics.SubscribeMsg(self, ePhysScriptMsgType.kMadePhysMsg);
                Physics.SubscribeMsg(self, ePhysScriptMsgType.kMadeNonPhysMsg);
            }
        } else {
            Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kFellAsleepMsg);

            if (DEBUG_PHYSICS) {
                Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
                Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
                Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
                Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kWokeUpMsg);
                Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kMadePhysMsg);
                Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kMadeNonPhysMsg);
            }
        }
    }

    function OnFrobInvEnd() {
        print("WitchesHead: " + message().message);
        // question: are we still contained at this point?
        local player = Object.Named("Player");
        local c = Container.IsHeld(self, player);
        if (c != eContainType.ECONTAIN_NULL) {
            print("  Object still contained by player at: " + c);
        } else {
            print("  Object no longer held by player.");

            // ISSUE: This is too soon to attach the camera! The throw hasn't
            // begun yet, but the throw direction gets derived from the camera
            // angle. As a result, attaching here causes throws to go straight
            // out from the player's chest.
            // print("Attaching camera to head.");
            // Camera.DynamicAttach(self);
        }
    }

    function OnContained() {
        print("WitchesHead: " + message().message);
        // well, we are definitely not still contained here, if the message is
        // right.

        if (message().event == eContainsEvent.kContainRemove) {
            // This is not robust against stacking. Let the level designer
            // avoid such possibilities!
            print("  Removed from container");
            // NOTE: We get a Contained/kContainRemove message at game start if
            // the witch's head is contained by the starting point or a
            // difficulty-level inventory container. So make sure we only
            // camera-attach when being removed from the player.
            local player = Object.Named("Player");
            if (message().container == player) {
                // BUG: Behaviour when dropped or when thrown is wildly different!
                //
                // When dropped: OBJ_ATTACH mode: no FOV change; no effect when
                // attaching/detaching camera.
                //      OnContained/kContainRemove
                //      Camera.DynamicAttach()
                //      PhysMadePhysical
                //
                // When thrown: REMOTE_CAM mode: forced wide FOV; fade-from-black/
                // fade-to-white when attaching/detaching camera.
                //      FrobInvEnd
                //      PhysMadePhysical
                //      OnContained/kContainRemove
                //      Camera.DynamicAttach()
                //
                // This difference occurs because camera.c:CameraRemote() hardcodes
                // these behavious based on whether the target has physics at
                // that moment.

                // print("Attaching camera to head.");
                // Camera.DynamicAttach(self); // variously OBJ_ATTACH or REMOTE_CAM
            }
        }
    }

    function OnPhysMadePhysical() {
        print("WitchesHead: " + message().message);
        // Either we have just started existing, or we have just been dropped
        // or thrown by the player.
        // TODO: don't attach the camera in the former case!

        // ISSUE: Although we have just been 'made physical', querying
        // Physics.HasPhysics() at this moment returns false! As a result,
        // doing the camera attach right now means we get the wrong mode
        // (OBJ_ATTACH) forced upon us due to lack of physics. Which means
        // no mouselook (and player is not frozen, but that's manageable).
        //
        // WORKAROUND: Post a message so we attach the camera next frame.
        PostMessage(self, "LookThroughEyes");

        //print("  Have physics? " + Physics.HasPhysics(self));

        // NOTE: this does not work to force 'has physics'
        //Physics.Activate(self);
        //print("  Have physics? " + Physics.HasPhysics(self));

        // print("  Attaching camera to head.");
        // Camera.DynamicAttach(self); // OBJ_ATTACH
    }

    // ISSUE: REMOTE_CAM/VIEW_CAM modes have hardcoded fade-in that is *much*
    // too long! This means you cannot see the arc of the head, nor see how
    // you are mouselooking it for the first, crucial moments of its flight!
    //
    // POSSIBLE SOLUTION: If we embrace the OBJ_ATTACH mode (which does NOT
    // freeze the player), and go ahead with teleporting the player to a blue
    // room, then the lack of freeze is acceptable.

    // BUG: if you click while the head is still moving through the air,
    // the camera is returned too early!
    //
    // SOLUTION: track CameraAttach/CameraDetach messages as well. And activate
    // the teleport if the player detaches mid-flight (perhaps also give the
    // player some of the velocity)

    function OnPhysMadeNonPhysical() {
        print("WitchesHead: " + message().message);
        print("  Returning camera to player.");
        Camera.CameraReturn(self);
    }

    function OnLookThroughEyes() {
        print("WitchesHead: " + message().message);
        // ISSUE: attaching now means we are forced to suffer the fade :(

        print("  Attaching camera to head.");
        //Camera.DynamicAttach(self); // REMOTE_CAM
        //Camera.StaticAttach(self); // VIEW_CAM
    }

    function OnPhysFellAsleep() {
        // BUG: Sometimes when the witch's head collides with a door, it stops
        //      moving but never receives a PhysFellAsleep message. This appears
        //      to occur more often when the head hits the door at an angle and
        //      remains very near it. When this happens, the head remains where
        //      it lands and neither the successful teleport nor the failure
        //      happen, which will leave the player stuck in the blue room.
        //      (When trying to replicate, temporarily disable the teleporting
        //      and watch the physics messages when you throw it repeatedly
        //      against the door).
        //
        // NOTE: This now seems to be happening a lot more even when colliding
        //      with just the ground (landing against the edge of the gravel
        //      path is a common place for it to occur).
        //
        // POSSIBLE WORKAROUND: Keep state to track the head in-flight or the
        //      head landed. Use a timer to periodically poll the head's
        //      velocity while in flight, and when it reaches a minimum, then
        //      do the teleport.

        print("WitchesHead: " + message().message);
        local controller = Object.Named("WitchesHeadController");
        SendMessage(controller, "Translocate", self);
    }

    function OnMessage() {
        print("WitchesHead: " + message().message);
    }
}

// All these are right out of PHYSAPI.H
const PLAYER_HEAD = 0;
const PLAYER_FOOT = 1;
const PLAYER_BODY = 2;
const PLAYER_KNEE = 3;
const PLAYER_SHIN = 4;
const PLAYER_RADIUS = 1.2;
const PLAYER_HEIGHT = 6.0;
// local PLAYER_HEAD_POS = ((PLAYER_HEIGHT / 2) - PLAYER_RADIUS);
// local PLAYER_FOOT_POS = (-(PLAYER_HEIGHT / 2));
// local PLAYER_BODY_POS = ((PLAYER_HEIGHT / 2) - (PLAYER_RADIUS * 3));
// local PLAYER_KNEE_POS = (-(PLAYER_HEIGHT * (13.0 / 30.0)));
// local PLAYER_SHIN_POS = (-(PLAYER_HEIGHT * (11.0 / 30.0)));

// The mission must have one and only one Marker, named "WitchesHeadController", with this WitchesHeadController
// script on it.
class WitchesHeadController extends SqRootScript
{
    has_setup = false;
    head_marker = 0;
    foot_marker = 0;
    body_marker = 0;
    head_probe = 0;
    body_probe = 0;
    foot_probe = 0;
    head_cam = 0;

    function OnDarkGameModeChange()
    {
        // OnSim is too soon (and gets called in-editor too!)
        // But OnDarkGameModeChange happens often. So make sure we only set up once.
        if (! has_setup) {
            SetupTranslocation();
            has_setup = true;
        }
    }

    function SetupTranslocation()
    {
        local player = Object.Named("Player");

        // Attach marker objects to submodels of the Player whose position we want to know.
        head_marker = GetSubmodelMarker("PlayerHeadMarker", player, PLAYER_HEAD);
        body_marker = GetSubmodelMarker("PlayerBodyMarker", player, PLAYER_BODY);
        foot_marker = GetSubmodelMarker("PlayerFootMarker", player, PLAYER_FOOT);

        // Create probe objects for collision tests prior to teleporting the player.
        head_probe = GetSphereProbe("PlayerHeadProbe", PLAYER_RADIUS);
        body_probe = GetSphereProbe("PlayerBodyProbe", PLAYER_RADIUS);
        foot_probe = GetSphereProbe("PlayerFootProbe", 0.0);
    }

    function OnTranslocate() {
        print("WitchesHeadController: " + message().message);
        local player = Object.Named("Player");
        local target = message().data;
        local pos = Object.Position(player);
        local facing = Object.Facing(player);

        // ISSUE: Witch's head that lands too close to a wall prevents
        // translocation because the player's radius won't fit that close.
        //
        // WORKAROUND: Ensure the witch's head has a radius of 1.2, the same
        // as the player.
        //
        // KNOCK-ON EFFECT: The larger radius prevents the witch's head from
        // being thrown through narrow openings--but that was one of the key
        // attractions of this design in the first place!
        //
        // POSSIBLE SOLUTION: Use a smaller radius, but figure out a different
        // way to deal with the too-close-to-a-wall issue.

        local foot_offset = (Object.Position(foot_marker) - pos);
        local target_radius = Property.Get(target, "PhysDims", "Radius 1");
        local new_pos = Object.Position(target) - foot_offset - vector(0,0,target_radius);
        local new_facing = Object.Facing(target); // TODO: use this

        local valid = Probe(new_pos);
        print((valid ? "Valid" : "Invalid") + " attempt to translocate from " + pos + " to " + new_pos);

        // ISSUE: player can end up inside an object after translocating, and we
        // cannot detect this with ValidPos() which only cares about terrain; nor
        // with Phys() messages, because they only occur on edges, not steady states.
        //
        // POSSIBLE WORKAROUND: when sim starts, scrape a list of all large-ish
        // immovable objects, get their positions, facings, and bounds, and store that.
        // Then query against that before teleporting to see if it should be allowed.
        //
        // POSSIBLE WORKAROUND: just dont let this happen in the level, you fool!

        // Pick up the head again (before teleporting, so they will not collide)
        Container.Add(target, player);

        if (valid) {
            Object.Teleport(player, new_pos, facing);
            Sound.PlayVoiceOver(player, "blue_light_on");

            // BUG: If player is abutting a wall to their East, then after teleporting,
            // they can't walk East again. Seems that teleporting the player doesn't
            // necessarily break physics contacts! (May also happen for other walls,
            // but is reliably reproducible with Eastern walls / objects.)
            //
            // SOLUTION: Setting the player's velocity seems to force contacts to be
            // re-evaluated, breaking the problematic contact. So we set it to what
            // it already is so that we don't interrupt their running/falling/whatever.
            local vel = vector();
            Physics.GetVelocity(player, vel);
            Physics.SetVelocity(player, vel);

            // BUG: If player translocates while in mid-mantle, they can still sometimes
            // get stuck midair, and teleport back if they abort the mantle! I can replicate
            // this most often with a wall to the player's South.
            //
            // RESOLUTION: Ignore. It will cause a visible glitch for the player, but there
            // will be no knock-on effects to worry about.

        } else /* ! valid */ {
            // Translocating now would put us inside a wall or something. That's not great.
            Sound.PlayVoiceOver(player, "blue_light_off");
        }
    }

    function Probe(pos) {
        local player = Object.Named("Player");
        local player_pos = Object.Position(player);
        local valid = true;
        if (valid) { valid = valid && EvaluateSingleProbe(head_probe, pos, head_marker, player_pos); }
        if (valid) { valid = valid && EvaluateSingleProbe(body_probe, pos, body_marker, player_pos); }
        if (valid) { valid = valid && EvaluateSingleProbe(foot_probe, pos, foot_marker, player_pos); }
        return valid;
    }

    function EvaluateSingleProbe(probe, probe_origin, marker, marker_origin) {
        local probe_pos = probe_origin + (Object.Position(marker) - marker_origin);
        Object.Teleport(probe, probe_pos, vector(0, 0, 0), 0);
        local valid = Physics.ValidPos(probe);
        return valid;
    }

    function GetSphereProbe(name, radius)
    {
        local obj = Object.Named(name);
        if (obj != 0) { return obj; }

        obj = Object.BeginCreate(Object.Named("Object"));
        Object.SetName(obj, name);

        // Probes all have a single sphere
        Property.Set(obj, "PhysType", "Type", 1);
        Property.Set(obj, "PhysType", "# Submodels", 1);
        Property.Set(obj, "PhysDims", "Radius 1", radius);
        Property.Set(obj, "PhysDims", "Offset 1", vector(0.0, 0.0, 0.0));

        // The probe must collide with anything but terrain.
        Property.Set(obj, "CollisionType", "", 0);
        Property.Set(obj, "PhysAIColl", "", false);

        // The probe starts at the origin.
        Object.Teleport(obj, vector(0,0,0), vector(0,0,0), 0);
        Physics.ControlCurrentLocation(obj);
        Physics.ControlCurrentRotation(obj);

        // Probe should not be rendered
        Property.Set(obj, "RenderType", "", 1);

        // Done.
        Object.EndCreate(obj);
        return obj;
    }

    function GetSubmodelMarker(name, target, submodel)
    {
        local obj = Object.Named(name);
        if (obj != 0) { return obj; }

        obj = Object.Create(Object.Named("Marker"));
        Object.SetName(obj, name);

        // Attach it to the appropriate submodel of the target
        local link = Link.Create("DetailAttachement", obj, target);
        LinkTools.LinkSetData(link, "Type", 3);
        LinkTools.LinkSetData(link, "vhot/sub #", submodel);
        LinkTools.LinkSetData(link, "rel pos", vector(0.0, 0.0, 0.0));
        LinkTools.LinkSetData(link, "rel rot", vector(0.0, 0.0, 0.0));

        return obj;
    }
}
