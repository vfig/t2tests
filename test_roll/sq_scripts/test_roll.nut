class DebugSpawnStuntDouble extends SqRootScript
{
    function OnTurnOn() {
        local o = Object.BeginCreate("StuntDouble");
        Object.Teleport(o, vector(), vector(), self);
        Object.EndCreate(o);
        //Property.Set(o, "PhysState", "Rot Velocity", vector(0,-8,0));
        Physics.ControlCurrentRotation(o);
        // TODO: make sure this goes in the right direction!!
        Physics.SetVelocity(o, vector(-30,0,0));
    }
}

class DebugSprint extends SqRootScript
{
    // 
    function OnTurnOn() {
        print("DebugSprint: "+message().message);
        DrkInv.AddSpeedControl("Sprint", 1.8, 1.0);
    }

    function OnTurnOff() {
        print("DebugSprint: "+message().message);
        DrkInv.RemoveSpeedControl("Sprint");
    }
}

class HackTeleport extends SqRootScript
{
    function OnTurnOn() {
        local target = LinkDest(Link.GetOne("Route", self));
        local player = Object.Named("Player");
        local relpos = Object.Position(player) - Object.Position(self)
        local pos = Object.Position(target)+relpos;
        local fac = Object.Facing(player);

        print("HackTeleporting to:"+pos);
        print("    old obj pos:"+Property.Get(player, "Position", "Location"));
        print("    old phys pos:"+Property.Get(player, "PhysState", "Location"));
        print("    old Player pos:"+Object.Position("Player"));

        if(true) {
            print("hack teleport");
            TeleportObj(player, pos, fac);
        } else {
            print("old fashioned teleport");
            Object.Teleport(player, pos, fac);
        }
        print("    new obj pos:"+Property.Get(player, "Position", "Location"));
        print("    new phys pos:"+Property.Get(player, "PhysState", "Location"));
        print("    new Player pos:"+Object.Position("Player"));

        // Debug.Command("player_cam_control 1");
        // Debug.Command("player_cam_control 1");
    }
}

class RoomDumpObjects extends SqRootScript
{
    function OnMessage() {
        switch (message().message) {
        case "PlayerRoomEnter":
        case "PlayerRoomExit":
        // case "RemotePlayerRoomEnter":
        // case "RemotePlayerRoomExit":
        case "CreatureRoomEnter":
        case "CreatureRoomExit":
        // case "ObjectRoomEnter":
        // case "ObjectRoomExit":
            print(desc(self)+" "+message().message+" -"
                +" "+desc(message().MoveObjId)+" moved"
                +" from:"+message().FromObjId
                +" to:"+ message().ToObjId);
            break;
        }
    }
}
