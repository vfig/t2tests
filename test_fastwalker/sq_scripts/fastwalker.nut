class FastWalker extends SqRootScript
{
    // timewarp = 1.0;
    // function OnBeginScript() {
        // if (Property.Possessed(self, "TimeWarp")) {
        //     timewarp = Property.Get(self, "TimeWarp");
        // }
    // }

    function OnAlertness() {
        // Okay, this isn't _too_ bad: it searches at 20x
        // speed initially; but it feels really weird when'
        // the zombie slows down heaps to walk towards the
        // player when trying to attack. Really the _walking_
        // speed needs changing here, not the entire time
        // warp that includes attack motions.
        local alertness_warp = [1.0, 1.0, 0.05, 1.0];
        local level = message().level;
        local warp = alertness_warp[level];
        Property.SetSimple(self, "TimeWarp", warp);
    }
}
