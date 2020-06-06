class AutoGravshaft extends SqRootScript {
    timer = 0;
    previousPitch = 999;
    particles = 0;

    function OnSim() {
        if (message().starting) {
            // Find the linked particles.
            local links = Link.GetAll("ScriptParams", self);
            foreach (link in links) {
                local link_data = LinkTools.LinkGetData(link, "");
                if (link_data == "Particles") {
                    particles = LinkDest(link);
                }
            }
            // Start them off in drifting mode.
            AdjustParticles(0);
        }
    }

    function OnPlayerRoomEnter() {
        local player = message().MoveObjId;
        local vel = vector();

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
        timer = SetOneShotTimer("ReadjustGravity", 0.25, player);
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

    function AdjustParticles(pitch) {
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
            timer = SetOneShotTimer("ReadjustGravity", 0.25, player);
        }
    }

    function OnPlayerRoomExit() {
        if (timer) {
            KillTimer(timer);
            timer = 0;
        }
        previousPitch = 999;
        AdjustParticles(0);
        local player = message().MoveObjId;
        Property.Set(player, "PhysAttr", "Gravity %", 100.0);
        Property.Set(player, "PhysAttr", "Base Friction", 0.0);
    }
}
