class DualCompass extends SqRootScript
{
    static POSES = {
        // POSE       top.x   bot.x,  eye.y   eye.x
        reset     = [  0.00,   0.00,   0.00,   0.00],
        blink     = [ 20.00,  20.00, 999.99, 999.99], // ignore eye.x and eye.y
        ahead     = [-25.71,  34.29,   0.34,  -5.71],
        left      = [-15.53,  44.47, -26.88,   4.47],
        right     = [-23.18,  36.82,  26.92,  -3.18],
        upleft    = [-43.82,  16.18,  -9.00, -23.82],
        upright   = [-43.73,  16.27,  19.08, -23.73],
        downleft  = [ -7.45,  50.00,  -8.82,  12.55],
        downright = [  3.91,  50.00,  20.52,  23.91],
        // TODO: up, down
    };

    function AnimateToRandomPose() {
        print("AnimateToRandomPose")
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
        print("AnimateToPose("+poseName+")");
        // Tweqs do not send TweqCompleted if they don't run at all (such as
        // if they're already at the target position), nor when one of the
        // joints has rate 0 (even if other joints should move*). So we take
        // those things into account below; and we use our own PoseCompleted
        // message instead of relying on TweqCompleted.
        //
        // *I had to change the eyelids from joints 3,4 to joints 1,2, because
        // when blinking only the eyelids got moved and TweqCompleted never
        // got sent :(

        //TODO: remove
        // print("---- FROM ----");
        // dump_joints();

        local blink = (poseName=="blink");
        local max_joint = blink ? 2 : 4;
        // TODO: when first 'waking up', this should be slower.
        local eye_speed = blink ? 800 : 400; // degrees/second
        local pose = POSES[poseName];
        local rate = [0,0,0,0];
        local lo = [0,0,0,0];
        local hi = [0,0,0,0];
        // Assign low and high tweq values.
        for (local j=0; j<max_joint; ++j) {
            local target = pose[j];
            local value = GetProperty("JointPos", JOINT_POS_FIELD[j]);
            lo[j] = (target<value) ? target : value;
            hi[j] = (target>value) ? target : value;
            rate[j] = (target>value) ? 1.0 : -1.0;
        }
        // Adjust rates so all joints complete simultaneously.
        local max_distance = 0.01;
        for (local j=0; j<max_joint; ++j) {
            local dist = fabs(hi[j]-lo[j]);
            if (dist>max_distance) max_distance = dist;
        }
        local eye_rate = eye_speed/10.0;
        local should_run_tweqs = false;
        for (local j=0; j<max_joint; ++j) {
            local dist = fabs(hi[j]-lo[j]);
            rate[j] *= eye_rate*dist/max_distance;
            if (fabs(rate[j])>0.01) should_run_tweqs = true;
        }
        // If no joints will animate, then we're done.
        if (!should_run_tweqs) {
            PostMessage(self, "PoseCompleted");
            return;
        }
        // Update the properties (for all joints).
        local cfg_flag = TWEQ_AC_SIM;
        if (blink) cfg_flag = cfg_flag|TWEQ_AC_1BOUNCE;
        for (local j=0; j<4; ++j) {
            if (fabs(rate[j])>0.01) {
                SetProperty("CfgTweqJoints", JOINT_ANIM_FIELD[j],
                    cfg_flag);
                SetProperty("CfgTweqJoints", JOINT_RANGE_FIELD[j],
                    vector(rate[j],lo[j],hi[j]));
                SetProperty("StTweqJoints", JOINT_STATE_ANIM_FIELD[j],
                    TWEQ_AS_ONOFF);
            }
        }

        SetProperty("CfgTweqJoints", "MiscC", TWEQ_MC_SCRIPTS);
        SetProperty("CfgTweqJoints", "AnimC", cfg_flag);
        SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);

        //TODO: remove
        // print("----- TO -----");
        // dump_joints();
    }

    function OnTweqComplete() {
        print(message().message);
        if (message().Type==eTweqType.kTweqTypeJoints) {
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
        for (local j=0; j<4; ++j) {
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

class DualCompassTest extends DualCompass
{
    function OnTurnOn() {
        local poseName = Property.Get(message().from, "DesignNote");
        if (!(poseName in POSES) && poseName!="random") {
            print("ERROR: unknown pose '"+poseName+"'");
            return;
        }
        print("");
        print("SET POSE: " + poseName);
        if (poseName=="random") {
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

class DualCompassInventory extends DualCompass
{
    // Inventory

    function OnSim() {
        print(message().message);
        SetData("DualCompassAnimating", false);
    }

    function OnInvSelect() {
        print(message().message);
        SetData("DualCompassAnimating", true);
        SetOneShotTimer("AnimateAgain", 3.0);
    }

    function OnInvDeSelect() {
        print(message().message);
        SetData("DualCompassAnimating", false);
        AnimateToPose("reset");
    }

    function OnPoseCompleted() {
        print(message().message);
        local keepAnimating = GetData("DualCompassAnimating");
        if (keepAnimating) {
            local r = (rand().tofloat()/RAND_MAX);
            local delay = 1.0+2.5*r;
            SetOneShotTimer("AnimateAgain", delay);
        }
    }

    function OnTimer() {
        print(message().message);
        if (message().name=="AnimateAgain") {
            local keepAnimating = GetData("DualCompassAnimating");
            if (keepAnimating) AnimateToRandomPose();
        }
    }
}