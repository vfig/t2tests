/* NOTES:
    For testing, we're going to use these, they should be easy to hear.
    But I might well need to create a custom schema for litelp1, since the
    flags on the AMB_MISC archetype might not be what I want!!

    //SEWER LITE    <--on "SewerLite" obj
    schema sewerlite_lp
    archetype AMB_MISC
    mono_loop 0 0
    volume -2000   //was -1500
    litelp1 litelp2 litelp3

    AMB_MISC:
        Volume: -1
        Initial Delay: 0
        Pan: 0
        Fade: 0                 <--- HMMM, WHAT IS THIS AND CAN I USE IT??
        Flags:
            [ ] Retrigger
            [ ] Pan position
            [ ] Pan Range
            [x] No Repeat
            [ ] No Cache
            [ ] Stream
            [ ] Play Once
            [ ] No Combat
            [x] Net Ambient
            [x] Local Spatial
            [x] ??
            [x] ??
            [x] ??
            [x] ??
            [x] ??
            [ ] ??
            [x] Noise
            [x] Speech
            [ ] Ambient
            [ ] Music
            [ ] MetaUI

    So the radius vs z is _really_ weird.
    A radius of 1.0 seems to always give a hard cutoff, even when only moving the
    source about 0.25 units!!
    But a radius of 2.0 is smoother, and cuts off a little before a 1.5 offset.

*/

class TestCrossfade extends SqRootScript
{
    CROSSFADE_TIMER_PERIOD = 0.016;
    CROSSFADE_DURATION = 2.0;
    CROSSFADE_Z_OFFSET = -1.5;
    source = 0;
    sourceLink = 0;

    function OnBeginScript() {
        print("self is " + self);
        local player = ObjID("Player");
        // Don't run on the start marker or anything else--only on the player.
        if (self != player) return;

        if (IsDataSet("CrossfadeSource")) {
            // FIXME: maybe save and load the links too?
            //       I don't know if objids let alone linkids are persisted across saves
            //       (probably, but not certainly), so may need to use names and Link.GetOne()
            //       here instead.
            source = GetData("CrossfadeSource").tointeger();
            //sourceLink = Link.GetOne(
            print("Retrieved crossfade source: " + source);
        } else {
            source = Object.BeginCreate("fnord");
            Object.Teleport(source, vector(), vector(), self);
            Property.Add(source, "AmbientHacked");
            Property.Set(source, "AmbientHacked", "Radius", 2.0);
            Property.Set(source, "AmbientHacked", "Flags", AMBFLG_S_NOSHARPCURVE); //|AMBFLG_S_TURNEDOFF
            // Note: there are interesting volume-related flags (add, scale, radius) available
            // for schemas, but AmbientHacked simply overrides all of them :/
            // And then it ignores its own "Override Volume" field :(
            Property.Set(source, "AmbientHacked", "Schema Name", "test_cf");
            // Make the source visible for debugging
            Property.SetSimple(source, "RenderType", 0);
            Property.SetSimple(source, "ModelName", "compass2");
            Object.EndCreate(source);
            SetData("CrossfadeSource", source.tointeger());
            print("Created crossfade source: " + source);

            // Gonna use a DetailAttachement to keep it attached to the player's head.
            sourceLink = Link.Create("DetailAttachement", source, self);
            LinkTools.LinkSetData(sourceLink, "Type", 3); // Submodel
            LinkTools.LinkSetData(sourceLink, "vhot/sub #", 0); // PLAYER_HEAD
            LinkTools.LinkSetData(sourceLink, "rel pos", vector());
            LinkTools.LinkSetData(sourceLink, "rel rot", vector());
            // Link "DetailAttachement"    // type sDetailAttachLinkData     , flags 0x0000
            // {
            //     "Type" : enum    // enums: "Object", "Vhot", "Joint", "Submodel", "Subobject", "Transparent Decal"
            //     "vhot/sub #" : uint
            //     "joint" : enum    // enums: "N/A", "Head", "Neck", "Abdomen", "Butt", "Left Shoulder", "Right Shoulder", "Left Elbow", "Right Elbow", "Left Wrist", "Right Wrist", "Left Fingers", "Right Fingers", "Left Hip", "Right Hip", "Left Knee", "Right Knee", "Left Ankle", "Right Ankle", "Left Toe", "Right Toe", "Tail"
            //     "rel pos" : vector
            //     "rel rot" : angvec
            //     "decal plane norm" : packednormal_hex
            //     "decal plane dist" : float
            //     "Flags" : bitflags    // flags: "No Auto-Delete", "No Joint Rot"
            // }
        }
    }

    function OnFadeIn() {
        local t = 0.0;
        local endT = 1.0;
        local time = GetTime();
        print("FadeIn - t: " + t + ", endT: " + endT + ", time: " + time);
        SetData("CrossfadeT", t);
        SetData("CrossfadeEndT", endT);
        SetData("CrossfadePrevTime", time);
        SetOneShotTimer("CrossfadeTimer", CROSSFADE_TIMER_PERIOD);
    }

    function OnFadeOut() {
        local t = 1.0;
        local endT = 0.0;
        local time = GetTime();
        print("FadeOut - t: " + t + ", endT: " + endT + ", time: " + time);
        SetData("CrossfadeT", t);
        SetData("CrossfadeEndT", endT);
        SetData("CrossfadePrevTime", time);
        SetOneShotTimer("CrossfadeTimer", CROSSFADE_TIMER_PERIOD);
    }

    function OnTimer() {
        if (message().name == "CrossfadeTimer") {
            local t = GetData("CrossfadeT");
            local endT = GetData("CrossfadeEndT");
            local prevTime = GetData("CrossfadePrevTime");
            local time = GetTime();
            local deltaTime = time - prevTime;
            if (endT > t) {
                // Fading up
                t = t + deltaTime/CROSSFADE_DURATION;
                if (t > endT) t = endT;
            } else {
                // Fading down
                t = t - deltaTime/CROSSFADE_DURATION;
                if (t < endT) t = endT;
            }
            SetData("CrossfadeT", t);
            SetData("CrossfadePrevTime", time);

            // Now position the source:
            local relpos = vector(0,0,t*CROSSFADE_Z_OFFSET);
            print("Timer - t: " + t + ", endT: " + endT + ", time: " + time + ", relpos: " + relpos);
            LinkTools.LinkSetData(sourceLink, "rel pos", relpos);

            // And check if we're finished.
            if (t == endT) {
                ClearData("CrossfadeT");
                ClearData("CrossfadeEndT");
                ClearData("CrossfadePrevTime");
                print("Crossfade done.");
            } else {
                SetOneShotTimer("CrossfadeTimer", CROSSFADE_TIMER_PERIOD);
            }
        }
    }
}

class TriggerFadeIn extends SqRootScript
{
    function OnFrobWorldEnd() {
        local player = ObjID("Player");
        print("Sending FadeIn to " + player);
        SendMessage(player, "FadeIn");
    }
}

class TriggerFadeOut extends SqRootScript
{
    function OnFrobWorldEnd() {
        local player = ObjID("Player");
        print("Sending FadeOut to " + player);
        SendMessage(player, "FadeOut");
    }
}
