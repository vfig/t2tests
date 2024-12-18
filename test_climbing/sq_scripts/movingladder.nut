class SineMovement extends SqRootScript
{
    function OnBeginScript() {
        SetData("ShuntingPlayer", false);
        // make sure we have a 60fps flicker tweq
        SetProperty("CfgTweqBlink", "Halt", TWEQ_STATUS_QUO);
        SetProperty("CfgTweqBlink", "AnimC", TWEQ_AC_NOLIMIT|TWEQ_AC_SIM);
        SetProperty("CfgTweqBlink", "MiscC", TWEQ_MC_SCRIPTS);
        SetProperty("CfgTweqBlink", "CurveC", 0);
        SetProperty("CfgTweqBlink", "Rate", 16);
        SetProperty("StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
        // need to find out when the player contacts us
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
    }

    function OnSim() {
        if (message().starting) {
            SetProperty("PhysControl", "Controls Active", 2); /* Velocity */
            SetProperty("PhysControl", "Velocity", vector());
            SetProperty("PhysAttr", "Gravity %", 0.0);
            SetData("BasePos", Object.Position(self));
        }
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            UpdatePosition(GetTime());
        }
    }

    function OnPhysContactCreate() {
        local o = message().contactObj;
        if (o==ObjID("Player")) {
            print("start shunting");
            SetData("ShuntingPlayer", true);
        }
    }

    function OnPhysContactDestroy() {
        local o = message().contactObj;
        if (o==ObjID("Player")) {
            print("stop shunting");
            SetData("ShuntingPlayer", false);
            Property.Remove(o, "ConveyorVel");
        }
    }

    function UpdatePosition(time) {
        local base_pos = GetData("BasePos");
        const mag = 6.0;
        const freq = 0.5; // per second
        local ref_pos = base_pos + vector(0,mag*sin(freq*time),0);
        local pos = Object.Position(self);
        local fac = Object.Facing(self);
        local dist = (ref_pos-pos);
        local error = dist.Length();
        local vel = dist*60.0;
        SetProperty("PhysControl", "Velocity", vel);
        if (error>=0.25) {
            // if the object is too far out of place, teleport it!
            //print("error is " + error + ", teleporting!");
            Object.Teleport(self, ref_pos, fac);
        }
        if (GetData("ShuntingPlayer")) {
            //add 5% to fudge past the hardcoded conveyor acceleration
            Property.Set(ObjID("Player"), "ConveyorVel", "", vel*1.05);
        }
    }
}

class SineMovementRope extends SqRootScript
{
    function OnBeginScript() {
        // make sure we have a 60fps flicker tweq
        SetProperty("CfgTweqBlink", "Halt", TWEQ_STATUS_QUO);
        SetProperty("CfgTweqBlink", "AnimC", TWEQ_AC_NOLIMIT|TWEQ_AC_SIM);
        SetProperty("CfgTweqBlink", "MiscC", TWEQ_MC_SCRIPTS);
        SetProperty("CfgTweqBlink", "CurveC", 0);
        SetProperty("CfgTweqBlink", "Rate", 8);
        SetProperty("StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
    }

    function OnSim() {
        if (message().starting) {
            SetData("BasePos", Object.Position(self));
        }
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            UpdatePosition(GetTime());
        }
    }

    function UpdatePosition(time) {
        local base_pos = GetData("BasePos");
        const mag = 6.0;
        const freq = 0.5; // per second
        local ref_pos = base_pos + vector(0,mag*sin(freq*time),0);
        local pos = Object.Position(self);
        local fac = Object.Facing(self);
        local vel = (ref_pos-pos);
        SetProperty("PhysState", "Location", ref_pos);
        // Unsure if this is needed, but it seems like
        // maybe a smoother ride with it:
        SetProperty("PhysState", "Velocity", vel);
    }
}

class GrowRope extends SqRootScript {
    function OnTurnOn() {
        // for some reason this doesnt work after five
        // to ten seconds after the mission starts. maybe the
        // rope is going to sleep or something?
        SetProperty("PhysRope", "Length", -15.0);
    }
}
