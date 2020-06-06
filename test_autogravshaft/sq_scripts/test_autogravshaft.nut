class AutoGravshaft extends SqRootScript {
    function OnPlayerRoomEnter() {
        local player = message().MoveObjId;
        Property.Set(player, "PhysAttr", "Gravity %", 0.0);
        Property.Set(player, "PhysAttr", "Base Friction", 1.0);
    }

    function OnPlayerRoomExit() {
        local player = message().MoveObjId;
        Property.Set(player, "PhysAttr", "Gravity %", 100.0);
        Property.Set(player, "PhysAttr", "Base Friction", 0.0);
    }
}



class GravshaftRoom extends SqRootScript {
    function OnPlayerRoomEnter() {
        print("GravshaftRoom:OnPlayerRoomEnter");
        local player = message().MoveObjId
        local toRoom = message().ToObjId

        local gravity = 100.0
        if (Property.Possessed(toRoom, "RoomGrav"))
            gravity = Property.Get(toRoom, "RoomGrav")
        Property.Set(player, "PhysAttr", "Gravity %", gravity)

        local vel = vector();
        Physics.GetVelocity(player, vel);
        vel.z += 1.0;
        Physics.SetVelocity(player, vel);
    }

    function OnPlayerRoomExit() {
        print("GravshaftRoom:OnPlayerRoomExit");
        local player = message().MoveObjId
        local toRoom = message().ToObjId
        local gravity = 100.0
        if (Property.Possessed(toRoom, "RoomGrav"))
            gravity = Property.Get(toRoom, "RoomGrav")
        Property.Set(player, "PhysAttr", "Gravity %", gravity)
    }
}

// Copied from tnhscript:
class ZeroGravRoom extends SqRootScript {
    function OnPlayerRoomEnter() {
        print("ZeroGravRoom:OnPlayerRoomEnter");
        local player = message().MoveObjId
        Property.Set(player, "PhysAttr", "Gravity %", 0.0)
        Property.Set(player, "PhysAttr", "Base Friction", 1.0)
    }

    function OnPlayerRoomExit() {
        print("ZeroGravRoom:OnPlayerRoomExit");
        local player = message().MoveObjId
        local toRoom = message().ToObjId
        local gravity = 100.0
        if (Property.Possessed(toRoom, "RoomGrav"))
            gravity = Property.Get(toRoom, "RoomGrav")
        Property.Set(player, "PhysAttr", "Gravity %", gravity)
    }
}
