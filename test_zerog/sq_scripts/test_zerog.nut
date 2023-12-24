/*

Okay, so controls wise this totally works as expected. Its very doable, if
rather limited in shape due to room brush shape limitations.

(Could this be triggered with a physics object instead, with a Sphere shape?
idk if they actually work as triggers. But a sphere shaped zone would be ideal!
UPDATE: sphere triggers simply dont get Enter/Exit messages, it would seem.)

UPDATE: using a sphere with a stim (larger radius than needed, but the script
thresholds the response to add/remove gravity+friction) absolutely works for
a sphere-shaped zero g area!

What doesnt work at all is the fog zone transitions. Even using a face-flipped
alpha-transparent unitbox to try to fake the fog from outside the volume still
doesnt work at all well. Probably better to think of some other way to indicate
the zone (visible boundary? and can ramp up the fog with script over time when
the player enters the zone)

*/

class ZeroGRoom extends SqRootScript {
    function GetGravity() {
        return 0.0;
    }

    function GetFriction() {
        return 0.2;
    }

    function OnPlayerRoomEnter() {
        DarkUI.TextMessage("Entered "+Object.GetName(self), 0, 1500);
        local gravity = GetGravity();
        local friction = GetFriction();
        local obj = message().MoveObjId
        Property.Set(obj, "PhysAttr", "Gravity %", gravity)
        Property.Set(obj, "PhysAttr", "Base Friction", friction)
    }

    function OnPlayerRoomExit() {
        local obj = message().MoveObjId
        local room = message().ToObjId
        local gravity = 100.0
        if (Property.Possessed(room, "RoomGrav"))
            gravity = Property.Get(room, "RoomGrav")
        Property.Set(obj, "PhysAttr", "Gravity %", gravity)
    }
}

class ZeroGDriftRoom extends ZeroGRoom {
    function GetFriction() {
        return 0.0;
    }
}

class ZeroGPhysicsObj extends SqRootScript {
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg
            |ePhysScriptMsgType.kCollisionMsg
            |ePhysScriptMsgType.kContactMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg
            |ePhysScriptMsgType.kCollisionMsg
            |ePhysScriptMsgType.kContactMsg);
    }

    function OnPhysEnter() {
        local obj = message().transObj;
        local objName = Object.GetName(obj)
        DarkUI.TextMessage(""+objName+" entered "+Object.GetName(self), 0, 1500);
    }

    function OnPhysExit() {
        local obj = message().transObj;
        local objName = Object.GetName(obj)
        DarkUI.TextMessage(""+objName+" exited "+Object.GetName(self), 0, 1500);
    }

    function OnPhysCollision() {
        local obj = message().collObj;
        local objName = Object.GetName(obj)
        DarkUI.TextMessage(""+objName+" collided with "+Object.GetName(self), 0, 1500);
    }

    function OnPhysPhysContactCreate() {
        local obj = message().contactObj;
        local objName = Object.GetName(obj)
        DarkUI.TextMessage(""+objName+" began contact with "+Object.GetName(self), 0, 1500);
    }

    function OnPhysPhysContactDestroy() {
        local obj = message().contactObj;
        local objName = Object.GetName(obj)
        DarkUI.TextMessage(""+objName+" ended contact with "+Object.GetName(self), 0, 1500);
    }
}

class ZeroGStimResponse extends SqRootScript {
    function OnPokeStimStimulus() {
        local intensity = message().intensity;
        local source = LinkDest(message().source)
        DarkUI.TextMessage("Stim "+intensity+" from "+Object.GetName(source), 0, 1500);

        local stimRad = 32.0;
        local zeroGRad = 24.0;
        local threshold = 100.0*(1.0-(zeroGRad/stimRad));
        local gravity = 1.0;
        local friction = 1.0;
        if (intensity>=threshold) {
            gravity = 0.0;
            friction = 0.0;
        } else {
            gravity = 0.0;
            friction = 0.2;
        }
        Property.Set(self, "PhysAttr", "Gravity %", gravity)
        Property.Set(self, "PhysAttr", "Base Friction", friction)
    }
}
