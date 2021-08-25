class DualCompass extends SqRootScript
{
    // TODO: stuff to set joint tweqs based on stored keyframes and start
    // it animating and respond to it finishing.
    //
    // but for a first pass we just want continually animating joint tweqs!

    /* PROBLEMS:
     *
     * 1. bsp.exe chokes on the exported file! if we only export the compass,
     *    eye parent, and eye, then it works. but including either or both of
     *    the lids borks it. i dont know how to begin resolving this.
     *
     * 2. all four joints animate just fine in the world (having exported an
     *    exploded version to temporarily work around #1). but in the inventory
     *    only the first two joints work?
    */

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
