// Add this script to a frobable object, to make it become FrobInert unless
// the camera is looking directly at it (with nothing else in the way).
//
// Useful for when you have a few frobable objects in very close proximity or
// even overlapping.
//
// This uses Tweq:Flicker, so is not compatible if you need Tweq:Flicker on
// the same object for any other purpose.
//
class RaycastFrob extends SqRootScript
{
    function OnBeginScript() {
        MakeFrobInert(true);
        EnableTweqBlink(true);
    }

    function OnEndScript() {
        MakeFrobInert(false);
        EnableTweqBlink(false);
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker
        && message().Op==eTweqOperation.kTweqOpFrameEvent) {
            if (RaycastHitMe()) {
                MakeFrobInert(false);
            } else {
                MakeFrobInert(true);
            }
        }
    }

    function MakeFrobInert(inert) {
        if (inert && !Object.HasMetaProperty(self, "FrobInert")) {
            Object.AddMetaProperty(self, "FrobInert");
        } else if (!inert && Object.HasMetaProperty(self, "FrobInert")) {
            Object.RemoveMetaProperty(self, "FrobInert");
        }
    }

    function EnableTweqBlink(enable) {
        if (! HasProperty("StTweqBlink")) {
            SetProperty("StTweqBlink", "AnimS", 0);
            SetProperty("CfgTweqBlink", "Halt", TWEQ_STATUS_QUO);
            SetProperty("CfgTweqBlink", "AnimC", TWEQ_AC_WRAP);
            SetProperty("CfgTweqBlink", "MiscC", TWEQ_MC_SCRIPTS);
            SetProperty("CfgTweqBlink", "CurveC", 0);
            SetProperty("CfgTweqBlink", "Rate", 8);
        }
        SetProperty("StTweqBlink", "AnimS", (enable? TWEQ_AS_ONOFF : 0));
    }

    function RaycastHitMe() {
        local dist = 7;
        if (HasProperty("PickDist")) {
            dist = GetProperty("PickDist");
        }
        local rayFrom = Camera.CameraToWorld(vector());
        local rayTo = Camera.CameraToWorld(vector(9,0,0));
        local refRayHitObj = object();
        local rayHitPos = vector();
        local hit = Engine.ObjRaycast(rayFrom, rayTo, rayHitPos, refRayHitObj, 0, 0x3, Object.Named("Player"), Object.Named("PlyrArm"));
        if (hit==2) { // Hit an object
            local rayHitObj = refRayHitObj.tointeger();
            return (rayHitObj==self);
        }
    }
}
