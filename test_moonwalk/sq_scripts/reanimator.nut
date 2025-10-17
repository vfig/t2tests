class Reanimator extends SqRootScript
{
    function OnBeginScript() {
        InitAnimate(message().time);
    }

    function InitAnimate(time) {
        SetData("StartTime", time);
        SetData("StartPos", GetProperty("Position", "Location"));
        SetData("Enable", 1);
        PostMessage(self, "ReanimatorTick");
    }

    function OnReanimatorTick() {
        SetProperty("TimeWarp", 0.0);
        Animate(message().time-GetData("StartTime"));
        if (GetData("Enable")==1)
            PostMessage(self, "ReanimatorTick");
    }

    function Animate(time) {
        //BH111o1o -- Locomote 0
        //BH213710 - Crumple 0, Die 0, IsConfied 0
        //BH213612 - Stalled 0, Flail 0, InWater 0, WithSword 0
        local duration = 4000; // HACK: we estimated this very roughly
        local frameRate = 60.0;
        // NOTE: using this fucked up approach to try to manually play the
        //       motion forward or backward is just too broken.
        // local frac = (time % duration).tofloat()/duration;
        // frac = 1.0-frac;
        // NOTE: but if we play it randomly, then isnt the brokenness a win?
        local frac = Data.RandFlt0to1();
        local targetTime = frac*duration*0.001;
        local timeWarp = 1.0/(targetTime*frameRate);
        SetProperty("TimeWarp", timeWarp);
        Puppet.PlayMotion(self, "BH213612");
        //SetData("Enable", 0); // TEMP
        SetProperty("Position", "Location", GetData("StartPos"));
    }

    // function OnMotionStart() {
    //     print(message().message
    //         +" action:"+message().ActionType
    //         +" motion:"+message().MotionName
    //         +" flag:"+message().FlagValue);
    // }

    // function OnMotionEnd() {
    //     print(message().message
    //         +" action:"+message().ActionType
    //         +" motion:"+message().MotionName
    //         +" flag:"+message().FlagValue);
    // }

    // function OnMotionFlagReached() {
    //     print(message().message
    //         +" action:"+message().ActionType
    //         +" motion:"+message().MotionName
    //         +" flag:"+message().FlagValue);
    // }

// class sBodyMsg extends sScrMsg
// {
//    const eBodyAction ActionType;
//    const string MotionName;
//    const int FlagValue;
// }

// enum eBodyAction
// {
//     kMotionStart
//     kMotionEnd
//     kMotionFlagReached
// }

}
