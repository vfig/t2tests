// put this on the StartingPt
class RaycastEverySecond extends SqRootScript
{
    function OnDarkGameModeChange() {
        if (!message().resuming && !message().suspending) {
            if (Object.InheritsFrom(self, "Avatar")) {
                print("Starting timer...");
                SetOneShotTimer("DoRaycasts", 1.0);
            }
        }
    }

    function OnTimer() {
        if (message().name=="DoRaycasts") {
            print("Repeating timer...");
            SetOneShotTimer("DoRaycasts", 1.0);
            SendMessage(self, "DoRaycasts");
        }
    }

    function OnDoRaycasts() {
        print("Doing raycasts...");
        local from = Object.Position(self);
        local to = from + vector(0,0,-16);
        local hit_pos = vector();
        local hit = Engine.PortalRaycast(from, to, hit_pos);
        if (hit) {
            print("Engine.PortalRaycast hit at " + hit_pos);
        }
        local hit_obj = object();
        local result = Engine.ObjRaycast(from, to, hit_pos, hit_obj,
            0, //short-circuit: 0 - none; 1 - any object; 2 - any terrain or object.
            0, //flags: 0x1 - ignore mesh objects; 0x2 - only normal/unlit objects.
            self, //ignore1: me
            Object.Named("RaycastMediumProbe") // ignore2
            );
        if (result) {
            // 1: terrain, 2: obj, 3: mesh obj)
            print("Engine.ObjRaycast hit type " + result + " at " + hit_pos + ": obj " + hit_obj);
        }

        if (!hit && !result) {
            // test for water!
            local probe = Object.Named("RaycastMediumProbe");
            local probe_pos = Object.Position(probe);
            print("Testing for water at time " + GetTime() + " with probe " + probe + " at " + probe_pos);
            local reset_pos = vector(0,0,10);

            ///  uuuuuuuugh the reset stuff isnt working the way i want! not sure why, and i cant think right now.
            if (probe_pos!=reset_pos) {
                print("Resetting probe position");
                local result = Object.Teleport(probe, reset_pos, vector());
                //print("Reset teleport result: " + result);
            }

            local result = Object.Teleport(probe, to, vector());
            //print("Teleport result: " + result);
        }
    }

    function OnProbeFoundWater() {
        print("Found water at time " + GetTime());
    }
}

class ReportMediumChanges extends SqRootScript {
    function OnMediumTransition() {
        // NO_MEDIUM              -1
        // MEDIA_SOLID             0
        // MEDIA_AIR               1
        // MEDIA_WATER             2
        //
        // These are used for doors:
        // MEDIA_SOLID_PERSIST     3
        // MEDIA_AIR_PERSIST       4
        // MEDIA_WATER_PERSIST     5
        print("from " + message().nFromType + " to " + message().nToType);
        if (message().nFromType==1 && message().nToType==2) {
            // TODO: experiment with underwater doors for MEDIA_WATER_PERSIST later?
            SendMessage("Player", "ProbeFoundWater");
        }
    }
}
