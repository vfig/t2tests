// Stuns this AI when hit with a stim.
// Requires NewDark v1.27 or higher.
//
// This uses WaterStim as an example. To use a different stim, edit
// this and rename OnWaterStimStimulus to e.g. "OnMyStimNameStimulus";
// the "On" prefix and "Stimulus" suffix must remain unchanged.
//
// To use:
//
// 1. Add a receptron for WaterStim to the AI (or archetype), with:
//      No Min, No Max, Effect: Send to Scripts.
//
// 2. Add the StimStun script to the AI (or archetype).
//
class StimStun extends SqRootScript
{
    function OnBeginScript() {
        // Version check: complain if on an old version of NewDark.
        if (GetAPIVersion() < 11) {
            DarkUI.TextMessage("ERROR: NewDark 1.27 required for StimStun!");
            Object.Destroy(self);
        }
    }

    function OnWaterStimStimulus() {
        DoStun(message().intensity);
    }

    function DoStun(intensity) {
        if (intensity >= 0.2) {
            // This will have no effect at intensities below 0.2,
            // and at higher intensities will stun the AI for between
            // 4 and 12 seconds (the latter at intensity 4.0+). This
            // mimics exactly the flashbomb intensity-to-stun-duration
            // calculation.
            if (intensity > 4.0) {
                intensity = 4.0;
            }
            local stunDuration = 4.0 + (2.0 * intensity);
            // Initially, play a motion with these tags (or if null,
            // just use the loop motion tags for the whole stun duration).
            local startMotionTags = null;
            // Then, play motions with these tags continually until the
            // stun duration has elapsed.
            local loopMotionTags = "Blinded 0, Stalled 0";
            // Now do it:
            AI.Stun(self, startMotionTags, loopMotionTags, stunDuration);
        }
    }
}
