class DualCompass extends SqRootScript
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

    static JOINT_VALUE_FIELD = [
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
            local jvalue = GetProperty("CfgTweqJoints", JOINT_VALUE_FIELD[j]);
            local janims = GetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j]);
            print("  AnimS: "+janims);
            print("  rate,lo,hi: "+jvalue);
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
        if (!forward) anim = anim|TWEQ_AS_REVERSE;
        Property.Set(self, "CfgTweqJoints", JOINT_VALUE_FIELD[j], vector(rate,lo,hi));
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
