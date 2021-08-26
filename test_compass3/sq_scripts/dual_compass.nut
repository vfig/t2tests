class DualCompass extends SqRootScript
{
    // TODO: stuff to set joint tweqs based on stored keyframes and start
    // it animating and respond to it finishing.
    //
    // but for a first pass we just want continually animating joint tweqs!

    function startTweqing() {
        Property.Set(self, "StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
        //ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeAll, eTweqDo.kTweqDoActivate);
    }
    function stopTweqing() {
        Property.Set(self, "StTweqJoints", "AnimS", 0);
        //ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeAll, eTweqDo.kTweqDoHalt);
    }

    // Inventory

    function OnInvSelect() {
        //startTweqing();
    }
    function OnInvDeSelect() {
        //stopTweqing();
    }
}
