class DualRoom extends SqRootScript
{
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
        print("BeginScript " + self);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
    }

    function OnPhysEnter() {
        local msg = message()
        local critter = msg.transObj;
        print("PhysEnter " + self + " by " + critter);
    }

    function OnPhysExit() {
        local msg = message()
        local critter = msg.transObj;

        print("PhysExit " + self + " by " + critter);
    }
}

class TrackingRoom extends SqRootScript
{
    function OnBeginScript() {
        print("BeginScript " + self);
    }

    function OnEndScript() {
    }

// Messages: "ObjRoomTransit", "PlayerRoomEnter", "PlayerRoomExit", "RemotePlayerRoomEnter", "RemotePlayerRoomExit",
//           "CreatureRoomEnter", "CreatureRoomExit", "ObjectRoomEnter", "ObjectRoomExit"

    function OnObjRoomTransit() {
        local msg = message()
        local critter = msg.MoveObjId;
        local from = msg.FromObjId;
        local to = msg.ToObjId;
        local type = "???";
        if (msg.TransitionType == eRoomChange.kEnter) {
            type = "Enter";
        } else if (msg.TransitionType == eRoomChange.kExit) {
            type = "Exit";
        } else if (msg.TransitionType == eRoomChange.kRoomTransit) {
            type = "Transit";
        }
        print("ObjRoomTransit " + self + " " + type + " by " + critter);
    }

    function OnObjectRoomEnter() {
        local msg = message()
        local critter = msg.MoveObjId;
        local from = msg.FromObjId;
        local to = msg.ToObjId;
        local type = "???";
        if (msg.TransitionType == eRoomChange.kEnter) {
            type = "Enter";
        } else if (msg.TransitionType == eRoomChange.kExit) {
            type = "Exit";
        } else if (msg.TransitionType == eRoomChange.kRoomTransit) {
            type = "Transit";
        }
        print("ObjectRoomEnter " + self + " " + type + " by " + critter);
    }

    function OnObjectRoomExit() {
        local msg = message()
        local critter = msg.MoveObjId;
        local from = msg.FromObjId;
        local to = msg.ToObjId;
        local type = "???";
        if (msg.TransitionType == eRoomChange.kEnter) {
            type = "Enter";
        } else if (msg.TransitionType == eRoomChange.kExit) {
            type = "Exit";
        } else if (msg.TransitionType == eRoomChange.kRoomTransit) {
            type = "Transit";
        }
        print("ObjectRoomExit " + self + " " + type + " by " + critter);
    }
}
