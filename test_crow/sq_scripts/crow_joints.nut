class BaseCrowJoints extends SqRootScript
{
    static MAX_JOINT = 5; // Joint 6 is not used at this time.

    static POSES = {
        // Neutral pose:
        reset           = [   0.0,   0.00,   0.00,    0.00,  0.00,    0.00 ],

        // Min/max rotation/joint values:
        range_min       = [ -40.0, -30.00, -30.00,  -60.00, -0.1,   -70.00 ],
        range_max       = [  40.0,  20.00,  30.00,   60.00,  0.1,    70.00 ],

        // Preset poses:
        // POSE             rotate,  legs, shoulder, neck, stretch,  head
        look_lefteye    = [ -15.0,   0.00,   0.00,  -30.00,  0.05,  -70.00 ],
        curious1        = [  10.0,   0.00,   0.00,  -47.86, -0.014,  12.87 ],
        weird           = [   0.0, -19.2407, -26.9055, -23.6133, 0.0820251, -85.6 ],
    };

    function AnimateToRandomPresetPose() {
        local choice = rand() % POSES.len();
        local i = 0;
        foreach (k,_ in POSES) {
            if (i==choice) {
                AnimateToPose(k);
                break;
            }
            ++i;
        }
    }

    function AnimateToPose(poseName) {
        local pose;
        if (poseName=="random") {
            pose = clone POSES.reset;
            for (local i=0; i<pose.len(); ++i) {
                local f = Data.RandFlt0to1();
                local fmin = POSES.range_min[i];
                local fmax = POSES.range_max[i];
                pose[i] = f*(fmax-fmin)+fmin;
            }
        } else {
            pose = clone POSES[poseName]
        }
        _AnimateJointsToPose(pose);
    }

    function _AnimateJointsToPose(pose) {
        // pose is an array: [z_rotation, legs_pitch, shoulder_pitch, neck_rotation, neck_stretch, head_rotation].
        //
        // NOTE: Tweqs do not send TweqCompleted if they don't run at all (such as
        // if they're already at the target position), nor when the primary
        // joint has rate 0 (even if other joints should move). So we take
        // those things into account below; and we use our own PoseCompleted
        // message instead of relying on TweqCompleted.
        print("Crow "+self+" pose is: ["+pose[0]+", "+pose[1]+", "+pose[2]+", "+pose[3]+", "+pose[4]+", "+pose[5]+"]");

        local rotate_speed = 300; // degrees/second
        local head_speed = 800;   //   ditto
        local body_speed = 300;   //   ditto
        local rate = [0,0,0,0,0,0,0]; // 0: z-rotation, 1-6: joints
        local lo = [0,0,0,0,0,0,0];   //   ditto
        local hi = [0,0,0,0,0,0,0];   //   ditto
        // Assign low and high tweq values.
        for (local j=0; j<=MAX_JOINT; ++j) {
            local target = pose[j];
            local value;
            switch (j) {
            case 0:
                value = Object.Facing(self).z;
                // TweqRotate cant handle -X to +X rotation, so we shove
                // the target into the other half of the circle.
                target += 180.0; if (target>360.0) target -= 360.0;
                break;
            default:
                value = GetProperty("JointPos", JOINT_POS_FIELD[j-1]);
                break;
            }
            lo[j] = (target<value) ? target : value;
            hi[j] = (target>value) ? target : value;
            rate[j] = (target>value) ? 1.0 : -1.0;
        }
        // Adjust rates so all joints complete ~simultaneously.
        local max_distance = 0.001;
        local max_is_rotate = false;
        for (local j=0; j<=MAX_JOINT; ++j) {
            local dist = fabs(hi[j]-lo[j]);
            if (dist>max_distance) {
                max_distance = dist;
                max_is_rotate = (j==0);
            }
        }
        local should_run_tweqs = false;
        for (local j=0; j<=MAX_JOINT; ++j) {
            local dist = fabs(hi[j]-lo[j]);
            local turn_rate;
            switch (j) {
            case 0:
                turn_rate = rotate_speed;
                break;
            case 1:
                turn_rate = body_speed;
                break;
            default:
                turn_rate = head_speed;
                break;
            }
            rate[j] *= 0.1*turn_rate*dist/max_distance;
            if (fabs(rate[j])>0.01) should_run_tweqs = true;
        }
        // If no joints will animate, then we're done.
        if (!should_run_tweqs) {
            PostMessage(self, "PoseCompleted");
            return;
        }
        // Update the properties (for all joints).
        for (local j=0; j<=MAX_JOINT; ++j) {
            if (fabs(rate[j])>0.01) {
                switch (j) {
                case 0:
                    SetProperty("CfgTweqRotate", "z rate-low-high",
                        vector(rate[j],lo[j],hi[j]));
                    break;
                default:
                    SetProperty("CfgTweqJoints", JOINT_ANIM_FIELD[j-1],
                        TWEQ_AC_SIM);
                    SetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[j-1],
                        vector(rate[j],lo[j],hi[j]));
                    SetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j-1],
                        TWEQ_AS_ONOFF);
                    break;
                }

            }
        }
        SetProperty("StTweqRotate", "AnimS", 0);
        SetProperty("CfgTweqRotate", "MiscC", (max_is_rotate? TWEQ_MC_SCRIPTS : 0));
        SetProperty("CfgTweqRotate", "AnimC", TWEQ_AC_SIM);
        SetProperty("CfgTweqRotate", "Primary Axis", 3);
        SetProperty("StTweqRotate", "AnimS", TWEQ_AS_ONOFF);

        SetProperty("StTweqJoints", "AnimS", 0);
        SetProperty("CfgTweqJoints", "MiscC", (max_is_rotate? 0 : TWEQ_MC_SCRIPTS));
        SetProperty("CfgTweqJoints", "AnimC", TWEQ_AC_SIM);
        SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
    }

    function OnTweqComplete() {
        // NOTE: We seem to be getting TweqComplete messages even when the
        //       Scripts flag is off. So we double check the flag here to know
        //       if the slowest thing (rotation or joints) is the one notifying
        //       us.
        local wasRotate = ( message().Type==eTweqType.kTweqTypeRotate
            && (GetProperty("CfgTweqRotate", "MiscC")&TWEQ_MC_SCRIPTS) );
        local wasJoints = ( message().Type==eTweqType.kTweqTypeJoints
            && (GetProperty("CfgTweqJoints", "MiscC")&TWEQ_MC_SCRIPTS) );
        if (wasJoints || wasRotate) {
            SendMessage(self, "PoseCompleted");
        }
    }

    static JOINT_ANIM_FIELD = [
        "Joint1AnimC", "Joint2AnimC", "Joint3AnimC",
        "Joint4AnimC", "Joint5AnimC", "Joint6AnimC",
    ];
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
        for (local j=0; j<=MAX_JOINT; ++j) {
            print("Joint "+j+":")
            local range = GetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[j]);
            local anims = GetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j]);
            print("  AnimS: "+anims);
            print("  rate,lo,hi: "+range);
            local value = GetProperty("JointPos", JOINT_POS_FIELD[j]);
            print("  pos: "+value);
        }
    }
}

class CrowJointsTest extends BaseCrowJoints
{
    function OnTurnOn() {
        local poseName = Property.Get(message().from, "DesignNote");
        if (!(poseName in POSES) && poseName!="random" && poseName!="randomPreset") {
            print("ERROR: unknown pose '"+poseName+"'");
            return;
        }
        print("");
        print("SET POSE: " + poseName);
        if (poseName=="randomPreset") {
            AnimateToRandomPose();
        } else {
            AnimateToPose(poseName);
        }
    }

    function OnPoseCompleted() {
        print(message().message);
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
        base.OnTweqComplete();
   }
}

class CrowJointsRandom extends BaseCrowJoints
{
    function OnSim() {
        if (message().starting) {
            SendMessage(self, "TurnOn");
        }
    }

    function OnTurnOn() {
        if (! IsDataSet("Active")) {
            SetData("Active", TRUE);
            AnimateToPose("random");
        }
    }

    function OnTurnOff() {
        ClearData("Active");
        if (IsDataSet("Timer")) {
            KillTimer(GetData("Timer"));
            ClearData("Timer");
        }
        AnimateToPose("reset");
    }

    function OnPoseCompleted() {
        if (IsDataSet("Active")) {
            StartTimer();
        }
    }

    function StartTimer() {
        local median = 2500;
        if (HasProperty("ScriptTiming")) {
            median = GetProperty("ScriptTiming");
        }
        local delay = median*(0.5 + Data.RandFlt0to1());
        if (IsDataSet("Timer")) print("BAD STATE, TIMER ALREADY SET!");
        SetData("Timer", SetOneShotTimer("Animate", 0.001*delay));
    }

    function OnTimer() {
        if (message().name=="Animate") {
            ClearData("Timer");
            if (IsDataSet("Active")) {
                AnimateToPose("random");
            }
        }
    }
}
