/* VFRotatable, by vfig - based on NVRotatable by NamelessVoice.

    This script allows its object to be rotated by the player holding
    down the frob button on it. Its TweqRotate is activated when it
    receives FrobWorldBegin, and deactivated when it receives FrobWorldEnd
    or WorldDeSelect.

    The script will send the StartRotate message to itself when it starts
    to rotate, and the StopRotate message one second after it has finished
    rotating.

    The script will send TurnOn and TurnOff messages via all ControlDevice
    links from the object when it starts and stops.

    The script will send TurnOn and TurnOff messages via all ControlDevice
    links from the object when it starts and stops.

    If the object has the Schema: Class Tags property, the script will play
    the schema with tags "<Class Tags>, Event ActiveLoop" when starting,
    and "<Class Tags>, Event Deactivate" when stopping, just like an elevator
    does.

    The object needs to have the Script and FocusScript flags set in the
    World Action of its Engine Features->Frob Info property. If you forget
    the latter, then the object will not stop rotating if you look away from
    it while it is moving.
*/
class VFRotatable extends SqRootScript {
    function Start(culprit) {
        local iAnimS = 0;
        if (Property.Possessed(self, "StTweqRotate")) {
            local mpAnimS = Property.Get(self, "StTweqRotate", "AnimS");
            iAnimS = (~mpAnimS & 2);
        }
        Property.Set(self, "StTweqRotate", "AnimS", iAnimS | 1);

        local fInitialSpeed = GetParam("VFRotatableInitialSpeed", 0.00).tofloat()
        if (fInitialSpeed) {
            if (Property.Possessed(self, "CfgTweqRotate")) {
                local mpSpeed = Property.Get(self, "CfgTweqRotate", "z rate-low-high");
                local vSpeed = vector();
                vSpeed.x = fInitialSpeed;
                vSpeed.y = 0.00;
                vSpeed.z = mpSpeed.z;
                Property.Set(self, "CfgTweqRotate", "z rate-low-high", vSpeed);
                EnableSpeedTimer(true);
            }
        }

        EnableStopTimer(false);
        PlaySound("Start", culprit);
        SendMessage(self, "StartRotate");
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }

    function Stop() {
        local wasRotating = false;
        local iAnimS = 0;
        if (Property.Possessed(self, "StTweqRotate")) {
            local mpAnimS = Property.Get(self, "StTweqRotate", "AnimS");
            if (mpAnimS & 1) {
                wasRotating = true;
            }
            iAnimS = (mpAnimS & ~1);
        }
        Property.Set(self, "StTweqRotate", "AnimS", iAnimS);

        EnableSpeedTimer(false);
        EnableStopTimer(true);

        if (wasRotating) {
            PlaySound("Stop", 0);
            Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
        }
    }

    function EnableSpeedTimer(enable) {
        local timer = GetData("SpeedTimer");
        if (timer) {
            // Stop speed-shift timer:
            KillTimer(timer);
            ClearData("SpeedTimer");
        }
        if (enable) {
            timer = SetOneShotTimer("VFRotateSpeedShift", 0.25);
            SetData("SpeedTimer", timer);
        }
    }

    function EnableStopTimer(enable) {
        local timer = GetData("StopTimer");
        if (timer) {
            // Stop timer:
            KillTimer(timer);
            ClearData("StopTimer");
        }
        if (enable) {
            timer = SetOneShotTimer("VFRotateStop", 1.0);
            SetData("StopTimer", timer);
        }
    }

    function OnTimer() {
        if (message().name=="VFRotateSpeedShift") {
            local fMaxSpeed = GetParam("VFRotatableMaxSpeed", 20.00).tofloat();

            if (Property.Possessed(self, "CfgTweqRotate")) {
                local mpSpeed = Property.Get(self, "CfgTweqRotate", "z rate-low-high");
                local vSpeed = vector();
                vSpeed.x = mpSpeed.x;
                vSpeed.y = 0.00;
                vSpeed.z = mpSpeed.z;
                if (vSpeed.x < fMaxSpeed) {
                    vSpeed.x += GetParam("VFRotatableAcceleration", 0.10).tofloat();
                    Property.Set(self, "CfgTweqRotate", "z rate-low-high", vSpeed);
                    EnableSpeedTimer(true);
                } else {
                    EnableSpeedTimer(false);
                }
            }
        } else if (message().name=="VFRotateStop") {
            SendMessage(self, "StopRotate");
            EnableStopTimer(false);
        }
    }

    function PlaySound(which, culprit) {
        Sound.HaltSchema(self);
        local class_tags = "";
        if (Property.Possessed(self, "Class Tags")) {
            class_tags = ", "+Property.Get(self, "Class Tags");
        } else {
            return;
        }
        if (which=="Start") {
            local tags = "Event ActiveLoop"+class_tags;
            Sound.PlayEnvSchema(self, tags, self, culprit, eEnvSoundLoc.kEnvSoundOnObj);
        } else {
            local tags = "Event Deactivate"+class_tags;
            Sound.PlayEnvSchema(self, tags, self, culprit, eEnvSoundLoc.kEnvSoundOnObj);
        }
    }

    function GetParam(name, default_value) {
        if (name in userparams()) {
            return userparams()[name];
        } else {
            return default_value;
        }
    }

    function OnFrobWorldBegin() {
        Start(message().Frobber);
    }

    function OnFrobWorldEnd() {
        Stop();
    }

    function OnWorldDeSelect() {
        Stop();
    }
}
