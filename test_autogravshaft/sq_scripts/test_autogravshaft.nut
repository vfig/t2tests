/* AutoGravShaft: a vertical shaft which the player can fly up and
** down in simply by looking up or down.
**
** 1. Create a Room Archetype, called e.g. "AutoGravshaft". Give it
**    the `AutoGravShaft` script.
** 2. If you want particles in the gravshaft, create a particle object,
**    and add a ScriptParams link from the room archetype to the particle
**    object, with the data set to "Particles". The particle object should
**    have the `StdParticleGroup` script.
** 3. If you want the grav shaft to be turned off initially, add
**    `AutoGravShaftOn=0;` to Editor>Design Note.
**
** The gravshaft will turn on and off in response to TurnOn and TurnOff
** messages send to the room archetype.
**
** Note: due to the way room objects work, you will need a new Room
** Archetype, set up as above, for each individual gravshaft.
*/
class AutoGravshaft extends SqRootScript {
    previousPitch = 999;

    function OnSim() {
        if (message().starting) {
            local startEnabled;
            if ("AutoGravShaftOn" in userparams()) {
                local onParam = userparams().AutoGravShaftOn.tointeger();
                print("::'"+onParam+"'");
                startEnabled = (onParam==1);
            } else {
                startEnabled = true;
            }
            SetEnabled(startEnabled, true);
        }
    }

    function OnPlayerRoomEnter() {
        SetPlayerInRoom(true);
    }

    function OnPlayerRoomExit() {
        SetPlayerInRoom(false);
    }

    function OnTurnOn() {
        SetEnabled(true);
    }

    function OnTurnOff() {
        SetEnabled(false);
    }

    function IsPlayerInRoom() {
        return (GetData("PlayerInRoom")==1);
    }

    function SetPlayerInRoom(inRoom) {
        if (inRoom==IsPlayerInRoom()) return;
        SetData("PlayerInRoom", (inRoom ? 1 : 0));
        if (inRoom) {
            if (IsEnabled())
                StartFiddlingWithGravity();
        } else {
            AdjustParticles(0);
            if (IsEnabled())
                StopFiddlingWithGravity();
        }
    }

    function IsEnabled() {
        return (GetData("Enabled")==1);
    }

    function SetEnabled(enabled, initial=false) {
        if (!initial) {
            if (enabled==IsEnabled()) return;
        }
        SetData("Enabled", (enabled ? 1 : 0));
        if (enabled) {
            SendMessage(GetParticles(), "TurnOn");
            AdjustParticles(0);
            if (IsPlayerInRoom())
                StartFiddlingWithGravity();
        } else {
            SendMessage(GetParticles(), "TurnOff");
            if (IsPlayerInRoom())
                StopFiddlingWithGravity();
        }
    }

    function StartFiddlingWithGravity() {
        local player = Object.Named("Player");
        local vel = vector();
        previousPitch = 999;

        // Make sure the player has air control when at zero gravity.
        Property.Set(player, "PhysAttr", "Base Friction", 1.0);

        AdjustPlayerGravity(player);
        local pitch = GetCameraPitch(player);
        if (pitch == 0) {
            // Kick the player off the ground a bit, but only if
            // they're looking level, so that we don't send them
            // flying under nonzero gravity!
            Physics.GetVelocity(player, vel);
            vel.z += 30.0;
            Physics.SetVelocity(player, vel);
        }
        local timer = SetOneShotTimer("ReadjustGravity", 0.25, player);
        SetData("GravityTimer", timer);
    }

    function StopFiddlingWithGravity() {
        local player = Object.Named("Player");
        local timer = GetData("GravityTimer");
        ClearData("GravityTimer");
        if (timer!=0) {
            KillTimer(timer);
        }
        Property.Set(player, "PhysAttr", "Gravity %", 100.0);
        Property.Set(player, "PhysAttr", "Base Friction", 0.0);
    }

    function AdjustPlayerGravity(player) {
        local pitch = GetCameraPitch(player);
        if (pitch != previousPitch) {
            local vel = vector();
            Physics.GetVelocity(player, vel);
            if (pitch > 0) {
                // Kick up a little, slow horizontal movement, and antigravity
                vel.x *= 0.2;
                vel.y *= 0.2;
                vel.z = 3.0;
                Property.Set(player, "PhysAttr", "Gravity %", -15.0);
            } else if (pitch < 0) {
                // Kick down a little, slow horizontal movement, and low gravity
                vel.x *= 0.8;
                vel.y *= 0.8;
                vel.z = -5.0;
                Property.Set(player, "PhysAttr", "Gravity %", 10.0);
            } else {
                // Immediately kill velocity, and zero gravity
                vel.z = 0.0;
                Property.Set(player, "PhysAttr", "Gravity %", 0.0);
            }
            Physics.SetVelocity(player, vel);
            AdjustParticles(pitch);
        }
        previousPitch = pitch;
    }

    function GetParticles() {
        if (IsDataSet("ParticlesObj")) {
            return GetData("ParticlesObj").tointeger();
        } else {
            // Find the linked particles.
            local particles = 0;
            local links = Link.GetAll("ScriptParams", self);
            foreach (link in links) {
                local link_data = LinkTools.LinkGetData(link, "");
                if (link_data == "Particles") {
                    particles = LinkDest(link).tointeger();
                    SetData("ParticlesObj", particles);
                }
            }
            return particles;
        }
    }

    function AdjustParticles(pitch) {
        local particles = GetParticles();
        if (particles == 0) return;
        local velMin = vector();
        local velMax = vector();
        if (pitch > 0) {
            velMin.z = 10;
            velMax.z = 15;
        } else if (pitch < 0) {
            velMin.z = -15;
            velMax.z = -10;
        } else {
            velMin.z = -0.5;
            velMax.z = 0.5;
        }
        Property.Set(particles, "PGLaunchInfo", "Velocity Min", velMin);
        Property.Set(particles, "PGLaunchInfo", "Velocity Max", velMax);
    }

    function GetCameraPitch(player) {
        local fac = Camera.GetFacing();
        local angle = fac.y;
        if (angle >= 270 && angle < (360.0 - 20.0)) {
            return 1.0;
        } else if (angle > 45.0 && angle <= 90.0) {
            return -1.0;
        } else if (angle > 90.0 && angle < 270.0) {
            // Shouldn't happen, but pretend it's the same as level.
            return 0.0;
        } else {
            return 0.0;
        }
    }

    function OnTimer() {
        if (message().name == "ReadjustGravity") {
            local player = message().data;
            AdjustPlayerGravity(player);
            local timer = SetOneShotTimer("ReadjustGravity", 0.25, player);
            SetData("GravityTimer", timer);
        }
    }
}
