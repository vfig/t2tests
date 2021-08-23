// set_saturation      :  overall saturation while in-game (with d3d_disp_sw_cc)
// set_brightness      :  overall brightness while in-game (with d3d_disp_sw_cc)
// set_contrast        :  overall contrast while in-game (with d3d_disp_sw_cc)
// set_colorfilter     :  overall color filter while in-game (with d3d_disp_sw_cc)

class ShaderController extends SqRootScript
{
    function ApplyColors() {
        local r = GetData("Red");
        local g = GetData("Green");
        local b = GetData("Blue");
        // Set shader parameters in a not-at-all hacky way!
        local args = (r + " " + g + " " + b);
        Debug.Command("set_colorfilter", args);
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
        SetData("Red", 1.0);
        SetData("Green", 1.0);
        SetData("Blue", 1.0);
        ApplyColors();
    }

    function OnSetRed() {
        local value = message().data.tofloat();
        SetData("Red", value);
        ApplyColors();
    }

    function OnSetGreen() {
        local value = message().data.tofloat();
        SetData("Green", value);
        ApplyColors();
    }

    function OnSetBlue() {
        local value = message().data.tofloat();
        SetData("Blue", value);
        ApplyColors();
    }
}

class RedLever extends SqRootScript
{
    function OnTurnOn() {
        print("RedLever " + message().message);
        local controller = Object.Named("ShaderController");
        SendMessage(controller, "SetRed", 0.5);
    }

    function OnTurnOff() {
        print("RedLever " + message().message);
        local controller = Object.Named("ShaderController");
        SendMessage(controller, "SetRed", 1.0);
    }
}

class GreenLever extends SqRootScript
{
    function OnTurnOn() {
        print("GreenLever " + message().message);
        local controller = Object.Named("ShaderController");
        SendMessage(controller, "SetGreen", 0.5);
    }

    function OnTurnOff() {
        print("GreenLever " + message().message);
        local controller = Object.Named("ShaderController");
        SendMessage(controller, "SetGreen", 1.0);
    }
}

class BlueLever extends SqRootScript
{
    function OnTurnOn() {
        print("BlueLever " + message().message);
        local controller = Object.Named("ShaderController");
        SendMessage(controller, "SetBlue", 0.5);
    }

    function OnTurnOff() {
        print("BlueLever " + message().message);
        local controller = Object.Named("ShaderController");
        SendMessage(controller, "SetBlue", 1.0);
    }
}

class LookAtMe extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            SetData("Timer", 0);
        }
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker
        && message().Op==eTweqOperation.kTweqOpFrameEvent) {
            // TODO: ramp up intensity smoothly instead of instantly?

            local time = GetTime();
            local intensity = 0.5+0.5*sin(4.0*time);
            local controller = Object.Named("ShaderController");
            SendMessage(controller, "SetGreen", intensity);

            local timer = GetData("Timer");
            if (timer!=0) {
                KillTimer(timer);
            }
            timer = SetOneShotTimer("Paused", 0.5);
            SetData("Timer", timer);
        }
    }

    function OnTimer() {
        // TODO: instead of a timer and instant off, we could have a second flicker object (in
        // the same spot? that, when we are looked at, we set the OffScreen flag on,
        // and it could be responsible for a smoother wind down.
        if (message().name=="Paused") {
            local controller = Object.Named("ShaderController");
            SendMessage(controller, "Reset");
            print("We are done.");
        }
    }
}
