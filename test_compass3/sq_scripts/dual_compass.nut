class DISABLED_DualCompass extends SqRootScript
{
    static POSES = {
        // POSE       eye.x   eye.y   top.x   bot.x
        reset     = [  0.00,   0.00,   0.00,   0.00],
        closed    = [  0.00,   0.00,  20.00,  20.00],
        ahead     = [ -5.71,   0.34, -25.71,  34.29],
        left      = [  4.47, -26.88, -15.53,  44.47],
        right     = [ -3.18,  26.92, -23.18,  36.82],
        upleft    = [-23.82,  -9.00, -43.82,  16.18],
        upright   = [-23.73,  19.08, -43.73,  16.27],
        downleft  = [ 12.55,  -8.82,  -7.45,  50.00],
        downright = [ 23.91,  20.52,   3.91,  50.00],
    };

    // TODO: stuff to set joint tweqs based on stored keyframes and start
    // it animating and respond to it finishing.
    //
    // but for a first pass we just want continually animating joint tweqs!

    static JOINT_RANGE_FIELD = [
        "    rate-low-high", "    rate-low-high2", "    rate-low-high3",
        "    rate-low-high4", "    rate-low-high5", "    rate-low-high6",
    ];
     //: bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
    static JOINT_STATE_ANIM_FIELD = [
        "Joint1AnimS", "Joint2AnimS", "Joint3AnimS",
        "Joint4AnimS", "Joint5AnimS", "Joint6AnimS",
    ];

    function dump_joints() {
        local anims = GetProperty("StTweqJoints", "AnimS");
        print("AnimS: "+anims);
        for (local j=0; j<4; ++j) {
            print("Joint "+j+":")
            local jrange = GetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[j]);
            local janims = GetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j]);
            print("  AnimS: "+janims);
            print("  rate,lo,hi: "+jrange);
            local pos = vector();
            local fac = vector();
            local ok = Object.CalcRelTransform(self, self, pos, fac, 3, j+1);
            fac.x = fac.x*180.0/3.14;
            fac.y = fac.y*180.0/3.14;
            fac.z = fac.z*180.0/3.14;
            print("  pos: "+pos);
            print("  fac: "+fac);
        }

    }
    function setJoint(j, rate, from, to) {
        local forward = (from<to);
        # hack! just throw an extra 30 degrees in here because
        # i need to flip things 180 because tweqs dont like the -ve to +ve change
        local lo = 30.0+ (forward ? from : to);
        local hi = 30.0+ (forward ? to : from);
        local anim = TWEQ_AS_ONOFF|TWEQ_AS_RESYNCH;
        if (!forward) rate = -rate;
        if (!forward) anim = anim|TWEQ_AS_REVERSE;
        Property.Set(self, "CfgTweqJoints", JOINT_RANGE_FIELD[j], vector(rate,lo,hi));
        Property.Set(self, "StTweqJoints", JOINT_STATE_ANIM_FIELD[j], anim);
        //Property.Set(self, "StTweqJoints", JOINT_STATE_FOO_FIELD[j], anim);
        print("  " + (j+1) + ": " + rate + "," + lo + "," + hi + " " + anim);
    }

    function transitionBetweenPoses(fromPoseName, toPoseName) {
        print("POSE: " + fromPoseName + " to " + toPoseName);
        local duration = 1.0; # TODO: pass the duration to setJoint and have it
                              #       calculate the rate for each joint accordingly
        local fromPose = POSES[fromPoseName];
        local toPose = POSES[toPoseName];
        setJoint(0, duration, fromPose[0], toPose[0]);
        setJoint(1, duration, fromPose[1], toPose[1]);
        setJoint(2, duration, fromPose[2], toPose[2]);
        setJoint(3, duration, fromPose[3], toPose[3]);
    }

    function startTweqing() {
        Property.Set(self, "StTweqJoints", "AnimS", TWEQ_AS_ONOFF|TWEQ_AS_RESYNCH);
        //ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeAll, eTweqDo.kTweqDoActivate);
    }
    function stopTweqing() {
        Property.Set(self, "StTweqJoints", "AnimS", 0);
        //ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeAll, eTweqDo.kTweqDoHalt);
    }

    // Inventory

    function OnInvSelect() {
        print("");
        print(message().message);
        local timer = GetData("timer");
        if (timer) KillTimer(timer);

        transitionBetweenPoses("closed", "downright");
        startTweqing();
        dump_joints();

        //timer = SetOneShotTimer("Animate", 2.0);
        //SetData("timer", timer);
    }

    function OnInvDeSelect() {
        print(message().message);
        stopTweqing();
        local timer = GetData("timer");
        if (timer) KillTimer(timer);
    }

    function OnTimer() {
        print(message().message + ", " + message().name);
        if (message().name=="Animate") {
            transitionBetweenPoses("closed", "downright");
            startTweqing();
            dump_joints();
        }
    }
}


class JointTest extends SqRootScript
{
    static JOINT_RANGE_FIELD = [
        "    rate-low-high", "    rate-low-high2", "    rate-low-high3",
        "    rate-low-high4", "    rate-low-high5", "    rate-low-high6",
    ];
     //: bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
    static JOINT_STATE_ANIM_FIELD = [
        "Joint1AnimS", "Joint2AnimS", "Joint3AnimS",
        "Joint4AnimS", "Joint5AnimS", "Joint6AnimS",
    ];

    static JOINT_POS_FIELD = [
        "Joint 1", "Joint 2", "Joint 3",
        "Joint 4", "Joint 5", "Joint 6",
    ];

    function dump_joints() {
        local anims = GetProperty("StTweqJoints", "AnimS");
        print("AnimS: "+anims);
        local JOINT_REFS = ["JointTestRef1"];
        local JOINT_MARKERS = ["JointTestJoint1"];
        for (local j=0; j<1; ++j) {
            print("Joint "+j+":")
            local jrange = GetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[j]);
            local janims = GetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j]);
            print("  AnimS: "+janims);
            print("  rate,lo,hi: "+jrange);
            local jvalue = GetProperty("JointPos", JOINT_POS_FIELD[j]);
            print("  pos: "+jvalue);
            local ref = Object.Named(JOINT_REFS[j]);
            local marker = Object.Named(JOINT_MARKERS[j]);
            local pos = vector();
            local fac = vector();
            local ok = Object.CalcRelTransform(ref, marker, pos, fac, 0, 0);
            print("  marker pos: "+pos);
            print("  marker fac: "+fac);
        }

    }
    function setJoint(rate,lo,hi) {
        SetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[0], vector(rate,lo,hi));
        SetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[0], TWEQ_AS_ONOFF);
    }

    function startTweq() {
        SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
    }
    function stopTweq() {
        SetProperty("StTweqJoints", "AnimS", 0);
    }

    function OnTurnOn() {
        print(message().message + " from " + Object.GetName(message().from));
        local goUp = (message().from==Object.Named("Up"));
        local goDown = (message().from==Object.Named("Down"));
        local stop = (message().from==Object.Named("Stop"));
        local res = (message().from==Object.Named("Resume"));

        dump_joints();

        if (goUp) {
            // rate is decadegrees/sec
            // i.e. rate 5.0 == 50 degrees/sec
            setJoint(5.0,0.0,90.0);
            startTweq();
        } else if (goDown) {
            local pos = GetProperty("JointPos", JOINT_POS_FIELD[0]);
            local lo = 5.0;
            local hi = pos;
            //local duration = 2000; // ms
            //local rate = (lo-hi)*100.0/duration
            local degrees_per_second = 50.0;
            local rate = -degrees_per_second/10.0;
            setJoint(rate,lo,hi);
            startTweq();
        } else if (stop) {
            local flag = GetProperty("StTweqJoints", "AnimS");
            flag = flag&~TWEQ_AS_ONOFF;
            SetProperty("StTweqJoints", "AnimS", flag);
            //stopTweq();
        } else if (res) {
            local flag = GetProperty("StTweqJoints", "AnimS");
            flag = flag|TWEQ_AS_ONOFF;
            SetProperty("StTweqJoints", "AnimS", flag);
        }
    }

    function OnTweqComplete() {
        print(message().message);
        if (message().Type==eTweqType.kTweqTypeJoints) {
            if (message().Dir==eTweqDirection.kTweqDirForward)
                print("  Dir: Forward");
            if (message().Dir==eTweqDirection.kTweqDirReverse)
                print("  Dir: Reverse");
            if (message().Op==eTweqOperation.kTweqOpKillAll)
                print("  Op: KillAll");
            if (message().Op==eTweqOperation.kTweqOpRemoveTweq)
                print("  Op: Remove");
            if (message().Op==eTweqOperation.kTweqOpHaltTweq)
                print("  Op: Halt");
            if (message().Op==eTweqOperation.kTweqOpStatusQuo)
                print("  Op: StatusQuo");
            if (message().Op==eTweqOperation.kTweqOpSlayAll)
                print("  Op: SlayAll");
            if (message().Op==eTweqOperation.kTweqOpFrameEvent)
                print("  Op: Frame");
        }
   }
}

class DualCompassTest extends SqRootScript
{
    static POSES = {
        // POSE       eye.y   eye.x   top.x   bot.x
        reset     = [  0.00,   0.00,   0.00,   0.00],
        blink     = [999.99, 999.99,  20.00,  20.00], // ignore eye.x and eye.y
        ahead     = [  0.34,  -5.71, -25.71,  34.29],
        left      = [-26.88,   4.47, -15.53,  44.47],
        right     = [ 26.92,  -3.18, -23.18,  36.82],
        upleft    = [ -9.00, -23.82, -43.82,  16.18],
        upright   = [ 19.08, -23.73, -43.73,  16.27],
        downleft  = [ -8.82,  12.55,  -7.45,  50.00],
        downright = [ 20.52,  23.91,   3.91,  50.00],
        // TODO: up, down
    };

    function OnTurnOn() {
        local poseName = Property.Get(message().from, "DesignNote");
        if (!(poseName in POSES)) {
            print("ERROR: unknown pose '"+poseName+"'");
            return;
        }
        if (poseName=="blink") {
            print("TODO: special-case blink!");
            return;
        }
        print("");
        print("SET POSE: " + poseName);
        const eye_duration = 150; // ms
        local pose = POSES[poseName];
        local lo = [0,0,0,0];
        local hi = [0,0,0,0];
        local rate = [0,0,0,0];
        // Assign low and high tweq values.
        for (local j=0; j<4; ++j) {
            local target = pose[j];
            local value = GetProperty("JointPos", JOINT_POS_FIELD[j]);
            lo[j] = (target<value) ? target : value;
            hi[j] = (target>value) ? target : value;
            rate[j] = (target>value) ? 1.0 : -1.0;
        }
        // Adjust rates so all joints complete simultaneously.
        local max_distance = 0;
        for (local j=0; j<4; ++j) {
            local dist = fabs(hi[j]-lo[j]);
            if (dist>max_distance) max_distance = dist;
        }
        local eye_rate = max_distance/eye_duration*100.0;
        for (local j=0; j<4; ++j) {
            local dist = fabs(hi[j]-lo[j]);
            rate[j] *= eye_rate*dist/max_distance;
        }
        // Update the properties.
        for (local j=0; j<4; ++j) {
            SetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[j],
                vector(rate[j],lo[j],hi[j]));
            SetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j],
                TWEQ_AS_ONOFF);
        }
        SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
        dump_joints();
    }

    static JOINT_RANGE_FIELD = [
        "    rate-low-high", "    rate-low-high2", "    rate-low-high3",
        "    rate-low-high4", "    rate-low-high5", "    rate-low-high6",
    ];
    static JOINT_STATE_ANIM_FIELD = [
        "Joint1AnimS", "Joint2AnimS", "Joint3AnimS",
        "Joint4AnimS", "Joint5AnimS", "Joint6AnimS",
    ];
    static JOINT_POS_FIELD = [
        "Joint 1", "Joint 2", "Joint 3",
        "Joint 4", "Joint 5", "Joint 6",
    ];

    function dump_joints() {
        local anims = GetProperty("StTweqJoints", "AnimS");
        print("AnimS: "+anims);
        for (local j=0; j<4; ++j) {
            print("Joint "+j+":")
            local jrange = GetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[j]);
            local janims = GetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j]);
            print("  AnimS: "+janims);
            print("  rate,lo,hi: "+jrange);
            local jvalue = GetProperty("JointPos", JOINT_POS_FIELD[j]);
            print("  pos: "+jvalue);
        }
    }
}
