class Translocator extends SqRootScript
{
    frob_start_time = 0;
    frob_max_duration = 1.0;
    frobwhile_period = 0.1;
    frobwhile_timer = 0;

    function OnFrobInvBegin() {
        frob_start_time = GetTime();

        // Start a timer for mid-frob updates and maximum frob time
        if (frobwhile_timer != 0) {
            KillTimer(frobwhile_timer);
            frobwhile_timer = 0;
        }
        frobwhile_timer = SetOneShotTimer(self, "FrobWhile", frobwhile_period);
    }

    function OnTimer() {
        if (message().name == "FrobWhile") {
            frobwhile_timer = 0;
            // Check if we've frobbed long enough
            local frob_duration = (GetTime() - frob_start_time);
            if (frob_duration >= frob_max_duration) {
                // Force frobbing to stop
                Debug.Command("use_item", 1);
            } else {
                // Keep the timer ticking
                frobwhile_timer = SetOneShotTimer(self, "FrobWhile", frobwhile_period);
            }
        }
    }

    function OnFrobInvEnd() {
        local frob_duration = message().Sec;
        if (frob_duration < frob_max_duration) {
            // Preview where we would translocate to if frobbed for a moment.
            local controller = Object.Named("DualController");
            SendMessage(controller, "Transview");
        } else {
            // Translocate if we frobbed for a while.
            local controller = Object.Named("DualController");
            SendMessage(controller, "Translocate");
        }
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

// The mission must have one and only one Marker, named "DualController", with this DualController
// script on it. It must have ScriptParams("DualOrigin") links to one or more Marker objects that
// represent the origins of the different worlds to translocate between.
//
// Each origin marker must have the DualOrigin script on it, and a ScriptParams("DualNext") link to
// the origin marker that corresponds to its alternate world.
//
// NOTE: Used to use a script attached to the StartingPoint (and thus the player) for translocation
// purposes, but changed it because links to the different DualOrigins weren't copied to the Player.
// And having the script on both the StartingPoint and the Player ended up problematic.
class DualController extends SqRootScript
{
    has_setup = false;
    head_marker = 0;
    foot_marker = 0;
    body_marker = 0;
    head_probe = 0;
    body_probe = 0;
    foot_probe = 0;
    head_cam = 0;
    all_worlds = null;
    current_world_index = 0;
    autoprobe_name = "AutoProbe";
    autoprobe_period = 0.1;
    autoprobe_timer = 0;

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

        // Find all the worlds, and figure out which the player starts in.
        all_worlds = FindAllWorlds();
        current_world_index = FindClosestWorldIndex(Object.Position(player));
        if (all_worlds.len() == 0 || current_world_index == null) {
            throw "Couldn't find any worlds!";
        } else {
            print("Found " + all_worlds.len() + " worlds, current is " + current_world_index);
        }

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

        /*
        // FIXME: this timer probably won't work w.r.t savegames because of the above. No matter.
        // FIXME: also the interval means we run the script much too often; we really don't need to.
        //
        // FIX: Put a Tweq/Flicker on the Translocator (enabled when contained by a Player), have it
        // send a message to the TranslocationMagic object, and use the return value to update the
        // Translocator's appearance.
        if (autoprobe_timer == 0) {
            autoprobe_timer = SetOneShotTimer(autoprobe_name, autoprobe_period);
        }
        */
    }

    function FindAllWorlds() {
        // Find all the ScriptParams:DualOrigin-linked markers
        local world_objs = [];
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local data = LinkTools.LinkGetData(link, "");
            if (data == "DualOrigin") {
                local o = LinkDest(link);
                world_objs.append(o);
            }
        }

        // Construct the world cache
        local worlds = [];
        foreach (o in world_objs) {
            local world = {
                obj = o,
                origin = Object.Position(o),
                scale = SendMessage(o, "DualScale"),
                next_obj = SendMessage(o, "DualNext"),
                next_index = null,
            };
            worlds.append(world);
        }

        // Link each world to the next by index
        foreach (index, world in worlds) {
            local next_index = world_objs.find(world.next_obj);
            if (next_index == null) {
                next_index = index;
            }
            world.next_index = next_index;
        }

        // Print out what we found
        foreach (index, world in worlds) {
            print("Found world " + index + ": "
                + Object.GetName(world.obj) + " (" + world.obj + ")"
                + " at: " + world.origin + ", scale: " + world.scale
                + ", next_obj: " + world.next_obj + ", next_index: " + world.next_index);
        }

        return worlds;
    }

    function FindClosestWorldIndex(pos) {
        local closest_index = null;
        local closest_distance = 1000000000.0;
        foreach(index, world in all_worlds) {
            // Because worlds can have different scales, we need to divide by
            // the scale to get relative positions that are comparable.
            local relative_pos = (pos - world.origin) / world.scale;
            local distance = relative_pos.Length();
            if (distance < closest_distance) {
                closest_distance = distance;
                closest_index = index;
            }
        }
        return closest_index;
    }

    function NextWorldIndex(index) {
        return all_worlds[index].next_index;
    }

    function WorldPos(pos, from_index, to_index) {
        local from_world = all_worlds[from_index];
        local to_world = all_worlds[to_index];
        local relative_pos = (pos - from_world.origin) / from_world.scale;
        return to_world.origin + (relative_pos * to_world.scale);
    }

    function OnTransview() {
        local player = Object.Named("Player");
        local pos = Object.Position(player);
        local facing = Object.Facing(player);
        local next_world_index = NextWorldIndex(current_world_index);
        local new_pos = WorldPos(pos, current_world_index, next_world_index);
        local valid = Probe(new_pos);

        // ISSUE: same collision issues as Translocate()

        if (valid) {
            AttachRemoteCameraTo(head_probe, head_cam);
            Sound.PlayVoiceOver(player, "blue_light_on");
        } else /* ! valid */ {
            // Transviewing now would put the camera inside a wall or something. That's not great.
            Sound.PlayVoiceOver(player, "blue_light_off");
        }
    }

    function OnTranslocate() {
        local player = Object.Named("Player");
        local pos = Object.Position(player);
        local facing = Object.Facing(player);
        local next_world_index = NextWorldIndex(current_world_index);
        local new_pos = WorldPos(pos, current_world_index, next_world_index);
        local valid = Probe(new_pos);
        print((valid ? "Valid" : "Invalid") + " attempt to translocate from " + pos + " in world " + current_world_index + " to " + new_pos + " in world " + next_world_index);

        // ISSUE: (if not using long frob) the player can translocate as fast as they
        // can mash the button.

        // ISSUE: player can end up inside an object after translocating, and we
        // cannot detect this with ValidPos() which only cares about terrain; nor
        // with Phys() messages, because they only occur on edges, not steady states.
        //
        // POSSIBLE WOKAROUND: when sim starts, scrape a list of all large-ish
        // immovable objects, get their positions, facings, and bounds, and store that.
        // Then query against that before teleporting to see if it should be allowed.

        if (valid) {
            current_world_index = next_world_index;
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
            // this most often with a wall to the player's South. This is an issue if I
            // try to store which world the player is in with a variable, instead of by
            // comparing player position to the reference points. Also an issue
            // for player equipment, if I'm taking that away when translocating.
            //
            // POSSIBLE WORKAROUND: Re-evaluate current world index every time we translocate
            // based on the closest origin. Then ending up in the wrong world by accident will
            // self-correct next time the player translocates.

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

    function OnTimer()
    {
        // if (message().name == autoprobe_name) {
        //     autoprobe_timer = SetOneShotTimer(autoprobe_name, autoprobe_period)
        // }
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

class DualOrigin extends SqRootScript
{
    function OnDualScale() {
        // FIXME: read userparams() for ScaleX, ScaleY, ScaleZ. Can't use the
        // Scale property, can we?
        Reply(vector(1.0));
    }

    function OnDualNext() {
        // Find the first ScriptParams:DualNext link (if any)
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local data = LinkTools.LinkGetData(link, "");
            if (data == "DualNext") {
                ReplyWithObj(LinkDest(link));
                return;
            }
        }
        ReplyWithObj(0);
    }

    function OnDualEnter() {
        // FIXME: get DualPlayer to send this when entering this world
    }

    function OnDualExit() {
        // FIXME: get DualPlayer to send this when exiting this world
    }
}
