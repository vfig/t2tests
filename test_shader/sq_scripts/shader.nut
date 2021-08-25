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
        if (visible) {
            // encode the bounds into the three shader params (in uv space):
            //      .x = center x
            //      .y = center y
            //      .z = radius
            // conveniently this will never be 1,1,1 (the default value for
            // the shader parameter we are hijacking), so the shader can
            // simply skip the effect when the input is 1,1,1.
            local x1 = rx1.tofloat();
            local y1 = ry1.tofloat();
            local x2 = rx2.tofloat();
            local y2 = ry2.tofloat();
            local sx = 0.5*(x1+x2)/w;
            local sy = 0.5*(y1+y2)/h;
            local sw = abs(x2-x1)/w;
            local sh = abs(y2-y1)/h;
            local sz = 0.5*sqrt(sw*sw+sh*sh);
            SetShaderParams(sx,sy,sz);
        } else {
            SetShaderParams(0,0,0);
        }
    }

    //function DrawTOverlay() {}
    //function OnUIEnterMode() {}
}

g_overlay <- LookAtMeOverlay();

class LookAtMe extends SqRootScript
{
    function destructor() {
        // to be on the safe side make really sure the handler is removed when this script is destroyed
        // (calling RemoveHandler if it's already been removed is no problem)
        DarkOverlay.RemoveHandler(g_overlay);
    }

    function OnBeginScript() {
        DarkOverlay.AddHandler(g_overlay);
        g_overlay.Init(self);
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
