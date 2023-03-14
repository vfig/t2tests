// set_saturation      :  overall saturation while in-game (with d3d_disp_sw_cc)
// set_brightness      :  overall brightness while in-game (with d3d_disp_sw_cc)
// set_contrast        :  overall contrast while in-game (with d3d_disp_sw_cc)
// set_colorfilter     :  overall color filter while in-game (with d3d_disp_sw_cc)

function SetShaderParams(r,g,b) {
    // Set shader parameters in a not-at-all hacky way!
    local args = (r.tofloat() + " " + g.tofloat() + " " + b.tofloat());
    // print("shader: " + args);
    Debug.Command("set_colorfilter", args);
}

function ResetShaderParams() {
    SetShaderParams(1,1,1);
}

// We're not drawing a HUD, but we're using the HUD api to get screen positions
// and to determine if the object in question is onscreen or not!
class LookAtMeOverlay extends IDarkOverlayHandler
{
    m_target = 0

    // keep these intrefs around so we dont create garbage every frame.
    rx1 = int_ref();
    ry1 = int_ref();
    rx2 = int_ref();
    ry2 = int_ref();

    function Init(target) {
        m_target = target;
    }

    // IDarkOverlayHandler interface

    function DrawHUD() {
        if (m_target==0) return;
        //local time = GetTime();
        //local intensity = 0.5+0.5*sin(4.0*time);

        // TODO: g_fNoiseTimer parameter in the shader repeats a bit too
        // quickly, so i would like to pass in a time value with a longer
        // period if i can.

        Engine.GetCanvasSize(rx1, ry1);
        local w = rx1.tofloat();
        local h = ry1.tofloat();
        local visible = DarkOverlay.GetObjectScreenBounds(m_target, rx1, ry1, rx2, ry2);
        /*
        local playerPos = Object.Position(Object.Named("Player"));
        local targetPos = Object.Position(m_target);
        local distance = (targetPos-playerPos).Length();
        const MAX_RANGE = 16.0;
        const MIN_RANGE = 2.0;
        local proximity = (MIN_RANGE+MAX_RANGE-distance)/MAX_RANGE;
        if (proximity<0.0) proximity = 0.0;
        if (proximity>0.999) proximity = 0.999;
        */
        if (visible /* || proximity>0.0 */) {
            // encode the bounds into the three shader params:
            //      .x = center x (in uv space)
            //      .y = center y (in uv space)
            //      .z = radius (in uv space)
            // make sure this is never 1,1,1 (the default value for
            // the shader parameter we are hijacking), or the shader
            // will simply skip the effect.
            local sx = 0.0;
            local sy = 0.0;
            local r = 0.0;
            if (visible) {
                local x1 = rx1.tofloat();
                local y1 = ry1.tofloat();
                local x2 = rx2.tofloat();
                local y2 = ry2.tofloat();
                sx = 0.5*(x1+x2)/w;
                sy = 0.5*(y1+y2)/h;
                local rx = 0.5*abs(x1-x2)/w;
                local ry = 0.5*abs(y1-y2)/h;
                r = rx; //(rx>ry)? rx : ry;
                if (r>0.999) r = 0.999;
            }
            local sz = r;
            SetShaderParams(sx,sy,sz);
        } else {
            SetShaderParams(0,0,0);
        }
    }

    //function DrawTOverlay() {}
    //function OnUIEnterMode() {}
}

g_overlay <- LookAtMeOverlay();

class OverlayHandler extends SqRootScript
{
    function destructor() {
        // to be on the safe side make really sure the handler is removed when this script is destroyed
        // (calling RemoveHandler if it's already been removed is no problem)
        DarkOverlay.RemoveHandler(g_overlay);
    }

    function OnBeginScript() {
        local link = Link.GetOne("ControlDevice", self);
        if (link) {
            DarkOverlay.AddHandler(g_overlay);
            g_overlay.Init(LinkDest(link));
        } else {
            print("ERROR: need ControlDevice link to target.");
        }
    }

    function OnEndScript() {
        DarkOverlay.RemoveHandler(g_overlay);
    }

    function OnSim() {
        if (message().starting) {
            // NOTE: ApplyColors() doesnt seem to work when the Sim message
            // comes in, so we post a reset message to ensure the filter
            // is reset when we start the game again.
            //SendMessage(self, "Reset");
            PostMessage(self, "Reset");
            // TODO: also send a reset if garrett wins or fails the mission!
        } else {
            // NOTE: doesnt work here!
            //SendMessage(self, "Reset");
        }
    }

    function OnReset() {
        ResetShaderParams();
    }
}
