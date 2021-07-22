/*  The Witch's Head: you become embodied in it when you throw it, and when it
    lands, you end up standing there.

    rough outline:

    when thrown:
        attach camera
        teleport player to specific blue room
    when landing:
      * check if theres room for the player
        if so:
            play success feedback sound + effect
          * teleport player there
            move witch's head to inventory
        if not:
            play failure feedback sound + effect
            teleport player back to original location
            move witch's head to inventory
*/
class ToolWitchesHead extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            Physics.SubscribeMsg(self, ePhysScriptMsgType.kFellAsleepMsg);
        } else {
            Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kFellAsleepMsg);
        }
    }

    // on throw: AttachRemoteCameraTo(head_probe, head_cam); ?? what are these params?

    function OnPhysFellAsleep() {
        print("WitchesHead: " + message().message);
        local controller = Object.Named("WitchesHeadController");
        print("found Controller: " + controller);
        SendMessage(controller, "Translocate", self);
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

const FORCE_OBJ_ATTACH_MODE = false;

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

        // FIXME: remove FORCE_OBJ_ATTACH_MODE, since it's got too many downsides.
        if (FORCE_OBJ_ATTACH_MODE) {
            // Create marker object for remote cam.
            head_cam = GetCamMarker("PlayerHeadCam");
        }
    }

    function OnTranslocate() {
        print("WitchesHeadController: " + message().message);
        local player = Object.Named("Player");
        local target = message().data;
        local pos = Object.Position(player);
        local facing = Object.Facing(player);
        local new_pos = Object.Position(target);
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

        // TODO: Pick up the head again
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

    function AttachRemoteCameraTo(probe, camera_marker) {
        local pos = Object.Position(probe);
        local facing = Camera.GetFacing();
        local attach_camera_to;

        if (FORCE_OBJ_ATTACH_MODE) {
            // NOTE: The cam object no physics model, so when calling Camera.DynamicAttach,
            // we get the OBJ_ATTACH camera mode instead of the normal REMOTE_CAM mode.
            // But that's good, because OBJ_ATTACH mode doesn't do the flash when starting
            // and ending, nor does it force the hard-coded remote cam FOV and lens overlay
            // either!
            // See camera.c:CameraRemote() and rend_loop.c:do_frame() for details.
            attach_camera_to = camera_marker;

            // BUG: When forcing OBJ_ATTACH mode, the camera position derived from the
            // head marker / head probe seems to be off compared to the player's actual
            // view. Need to debug with Camera.GetPosition() and compare to the marker
            // or probe's position.

            // BUG: When forcing OBJ_ATTACH mode with Camera.DynamicAttach, player input
            // is not stopped. So the player can move, can use items and so on. This is
            // pretty bad. So despite the visual advantages, might not want to use it.

            // BUG: When forcing OBJ_ATTACH mode with Camera.DynamicAttach, the player's
            // camera is reset to straight and level after returning (although z rotation
            // remains unchanged). This is disorienting.
        } else {
            attach_camera_to = probe;

            // NOTE: Can customise camera/camovl.txt somewhat to adjust the appearance of the
            // lens overlay to be more suitable. But the remote camera FOV is hard-coded.
            // Or can just use the NewDark Renderer/Camera Overlay property, for a different
            // set of possible effects.

            // BUG: When using Camera.DynamicAttach to a probe, the rotation of the probe's
            // facing seems to end up doubled. Perhaps bug relating to the FOV change?
            // (Note that this affects CamGrenades too, but since they're thrown, their
            // initial orientation is somewhat random anyway, so who would notice?)
            //
            // WORKAROUND: Halve each component of the camera's facing so the transview
            // cameras is looking the same way as the player was when activating it.
            facing.x /= 2.0;
            facing.y /= 2.0;
            facing.z /= 2.0;
        }

        Object.Teleport(attach_camera_to, pos, facing, 0);
        Camera.DynamicAttach(attach_camera_to);
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

    function GetCamMarker(name)
    {
        local obj = Object.Named(name);
        if (obj != 0) { return obj; }

        obj = Object.Create(Object.Named("Marker"));
        Object.SetName(obj, name);

        return obj;
    }
}
