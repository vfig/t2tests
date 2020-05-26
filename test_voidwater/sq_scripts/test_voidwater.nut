class VoidRoom extends SqRootScript
{
    function OnBeginScript() {
        print("VoidRoom is alive!");
    }

    playerInRoom = false;
    pushbackForce = vector(0.0, -200.0, 0.0);
    pushbackVelocity = vector();
    pushbackTimer = null;
    pushbackInterval = 0.016;
    // controlVelocity = vector();

    function OnPlayerRoomEnter() {
        print("Player entered!");
        local player = Object.Named("Player");
        local playerVelocity = Property.Get(player, "PhysState", "Velocity");
        print("  playerVelocity: " + playerVelocity);
        playerInRoom = true;
        pushbackVelocity = vector();
        pushbackTimer = SetOneShotTimer("pushback", pushbackInterval);
//        Property.Set(player, "PhysAttr", "Gravity %", 0.0)
//        Property.Set(player, "PhysAttr", "Base Friction", 0.0)
        /* STATUS: This seems to work okay, but when jumping in occasionally we get
           flung upwards??? Not a big deal though, as long as I make sure the rooms
           in question are shaped to properly funnel the player out the exist without
           ever getting caught up on anything (like doors). */
    }

    function OnPlayerRoomExit() {
        print("Player exited!");
        if (playerInRoom) {
            playerInRoom = false;
            local player = Object.Named("Player");
            Property.Set(player, "PhysAttr", "Gravity %", 100.0)
            //Property.Set(player, "PhysAttr", "Base Friction", 1.0)
            if (pushbackTimer) {
                KillTimer(pushbackTimer);
                pushbackTimer = null;
            }
        }
    }

    function OnTimer() {
        if (message().name == "pushback") {
            local player = Object.Named("Player");
            local playerVelocity = Property.Get(player, "PhysState", "Velocity");
            print("  playerVelocity: " + playerVelocity);

            // If setting PhysState directly, the teleport is needed to cut off
            // all the existing acceleration and whatnot (but it will also kill
            // AI awareness links). It will work, though.
            // But using Physics.SetVelocity, I don't need to!
//            local pos = Object.Position(player);
//            local fac = Object.Facing(player);
//            Object.Teleport(player, pos, fac, 0);
            pushbackVelocity = pushbackVelocity + pushbackForce * pushbackInterval 
            local newVelocity = playerVelocity + pushbackVelocity * pushbackInterval;
            print("  newVelocity: " + newVelocity);
//            Property.Set(player, "PhysState", "Velocity", newVelocity);
            Physics.SetVelocity(player, newVelocity);

            pushbackTimer = SetOneShotTimer("pushback", pushbackInterval);
        }
    }
}
