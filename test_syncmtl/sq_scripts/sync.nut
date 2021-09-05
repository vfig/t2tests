class TextureDoor extends SqRootScript
{
    function OnDoorOpening() {
        SetProperty("OTxtRepr0", "obj\\txt\\craygran0");
    }

    function OnDoorOpen() {
        SetProperty("OTxtRepr0", "obj\\txt\\craygran");
    }

    function OnDoorClosing() {
        SetProperty("OTxtRepr0", "obj\\txt\\craygran1");
    }

    function OnDoorClose() {
        SetProperty("OTxtRepr0", "obj\\txt\\craygran");
    }

    function OnDoorHalt() {
        SetProperty("OTxtRepr0", "obj\\txt\\craygran");
    }
}

class ToggleDoorBase extends SqRootScript
{
    function GetPhaseAdjust() {
        return 0.0;
    }

    function OpenTheDoor() {
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }

    function CloseTheDoor() {
        Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
    }

    function OnTurnOn() {
        local door = LinkDest(Link.GetOne("ControlDevice", self));
        local msg;
        local state = Door.GetDoorState(door);
        if (state==eDoorStatus.kDoorOpen) {
            msg = "CloseTheDoor";
        } else if (state==eDoorStatus.kDoorClosed) {
            msg = "OpenTheDoor";
        } else {
            // do nothing!
            return;
        }
        local period = 2.0;
        local phase_adjust = GetPhaseAdjust();
        local t = (GetTime() / period) + phase_adjust;
        local phase = t - floor(t);
        if (phase < 0.05) {
            print("going immediately!");
            OpenTheDoor();
        } else {
            local delay = period*(1.0-phase);
            print("going after " + delay);
            SetOneShotTimer(msg, delay);
        }
    }

    function OnTimer() {
        if (message().name=="OpenTheDoor") {
            print("delay complete, going now.");
            OpenTheDoor();
        } else if (message().name=="CloseTheDoor") {
            print("delay complete, going now.");
            CloseTheDoor();
        }
    }
}

class ToggleDoorAtPhase00 extends ToggleDoorBase
{
    function GetPhaseAdjust() {
        return 0.0;
    }
}
