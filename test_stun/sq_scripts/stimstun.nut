// Stuns this AI when hit with a stim.
// Requires NewDark v1.27 or higher.
//
// This uses WaterStim as a placeholder. To use a different stim, edit
// this and replace WaterStim everywhere with the name of your chosen stim.
//
// To use:
//
// 1. Add a receptron for WaterStim to the AI (or archetype), with:
//      No Min, No Max, Effect: Send to Scripts.
//
// 2. Add the WaterStimStun script to the AI (or archetype).
//
class WaterStimStun extends SqRootScript
{
    function OnBeginScript() {
        // Version check: complain if on an old version of NewDark.
        if (GetAPIVersion() < 11) {
            DarkUI.TextMessage("NewDark 1.27 required for WaterStimStun!");
            Object.Destroy(self);
        }
    }

    function OnWaterStimStimulus() {
        local intensity = message().intensity;
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
