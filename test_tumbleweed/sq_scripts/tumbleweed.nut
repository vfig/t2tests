class Tumbleweed extends SqRootScript {
    SPEED = 10.0;
    COLLISION_COS = 0.643; // cos(50 degrees)

    function OnBeginScript() {
        SetData("Angle", Object.Facing(self).z);
        SetData("RollTimer", 0);
        SetData("JokesOver", false);
        SetData("Stopped", false);
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnPhysCollision() {
        local n = message().collNormal;
        local dir = GetDirection();
        local res = n.Dot(dir);
        if (fabs(res) >= COLLISION_COS) {
            StopRolling();
        }
    }

    function OnTurnOn() {
        if (! GetData("Stopped")) {
            Roll();
        }
    }

    function OnTimer() {
        if (message().name=="Roll") {
            Roll();
        }
    }

    function OnContained() {
        StopRolling();
    }

    function OnTurnOff() {
        StopRolling();
    }

    function GetDirection() {
        local a = GetData("Angle");
        local rand = Data.RandFltNeg1to1();
        a += rand*10.0;
        a *= 3.1416/180.0;
        return vector(cos(a), sin(a), 0.0);
    }

    function IsBigJoke() {
        if (! GetData("JokesOver")) {
            // Run away the first time the player gets close.
            local player = ObjID("Player");
            if (player) {
                local d = Object.Position(player)-Object.Position(self);
                local dist2 = d.Dot(d);
                if (dist2<(10*10)) {
                    SetData("JokesOver", true);
                    return true;
                }
            }
        }
        return false;
    }

    function Roll() {
        local joke = IsBigJoke();
        local rand = Data.RandFlt0to1();
        if (rand<=0.5 || joke) {
            // Calculate new velocities.
            local move = GetDirection()*SPEED;
            local vel = GetProperty("PhysState", "Velocity");
            local rot = GetProperty("PhysState", "Rot Velocity");
            vel.x = move.x;
            vel.y = move.y;
            rot.x = -4*move.y;
            rot.y = 4*move.x;
            // Go twice as fast when there's a gust.
            rand = Data.RandFlt0to1();
            if (rand<=0.25 || joke) {
                vel = vel*2.0;
                rot = rot*2.0;
            }
            // Apply the new velocities.
            SetProperty("PhysControl", "Velocity", vel);
            SetProperty("PhysControl", "RotationalVelocity", rot);
            SetProperty("PhysControl", "Controls Active", 0x06); // Velocity|Rot Velocity
        } else {
            // Let physics take control again.
            SetProperty("PhysControl", "Controls Active", 0x00);
        }
        rand = Data.RandFlt0to1();
        local timer = SetOneShotTimer("Roll", 0.3+1.0*rand);
        SetData("RollTimer", timer);
    }

    function StopRolling() {
        SetData("Stopped", true);
        // Kill the timer
        local timer = GetData("RollTimer");
        SetData("RollTimer", 0);
        KillTimer(timer);
        // Let physics take control again.
        SetProperty("PhysControl", "Controls Active", 0x00);
        // Stop listening for physics messages.
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }
}
