class SineMovement extends SqRootScript
{
    function OnBeginScript() {
        SetProperty("CfgTweqBlink", "Halt", TWEQ_STATUS_QUO);
        SetProperty("CfgTweqBlink", "AnimC", TWEQ_AC_NOLIMIT|TWEQ_AC_SIM);
        SetProperty("CfgTweqBlink", "MiscC", TWEQ_MC_SCRIPTS);
        SetProperty("CfgTweqBlink", "CurveC", 0);
        SetProperty("CfgTweqBlink", "Rate", 16);
        SetProperty("StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
    }

    function OnSim() {
        if (message().starting) {
            // Velocity: 2, Location: 8, Rotation: 16
            SetProperty("PhysControl", "Controls Active", 2);
            SetProperty("PhysControl", "Velocity", vector());
        }
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            UpdatePosition(GetTime());
            //print("Blink");
        }
    }

    function UpdatePosition(time) {
        local base_pos = vector(6.0,0.0,-2.0);
        const mag = 6.0;
        const freq = 0.5; // per second
        local ref_pos = base_pos + vector(0,mag*sin(freq*time),0);
        local pos = Object.Position(self);
        local fac = Object.Facing(self);
        local dist = (ref_pos-pos);
        local error = dist.Length();
        SetProperty("PhysControl", "Velocity", dist*60.0);
        if (error>=0.25) {
            print("error is " + error + ", teleporting!");
            Object.Teleport(self, ref_pos, fac);
        }
    }
}
