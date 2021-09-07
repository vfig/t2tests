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
        local vel = (ref_pos-pos); //*0.01667;
        SetProperty("PhysControl", "Velocity", vel*60.0);
        print("error: " + (ref_pos-pos).Length());
        //print("vel: " + vel);
        //SetProperty("ConveyorVel", vel);

        // FIXME: use ConveyorVelocity? or just set physics values directly?
        //Object.Teleport(self, pos, fac);
    }
}
