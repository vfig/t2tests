class FacePuppetteer extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            PostMessage(self, "TurnOn");
        }
    }

    function OnTurnOn() {
        local motion = "facelook";
        SetData("CurrentMotion", motion);
        PlayMotion(motion);
    }

    function OnTurnOff() {
        local start_time = GetData("MotionStart").tofloat();
        local duration = (GetTime() - start_time);
        print("Duration: " + duration);
        // Loop the motion if its more than a couple frames
        if (duration > 0.035) {
            PlayMotion(GetData("CurrentMotion"));
        }
    }

    function PlayMotion(index) {
        local puppet = LinkDest(Link.GetOne("ControlDevice", self));
        if (puppet != 0) {
            // Teleport the puppet back to our position (so motion offsets don't accumulate)
            Object.Teleport(puppet, vector(), vector(), self);

            // Get the motion name
            local motion = GetData("CurrentMotion");

            // Display which motion we're playing
            local message = motion;
            print("CurrentMotion: "+message);
            DarkUI.TextMessage(message, 0xFFFFFF, 30000);

            SetData("MotionStart", GetTime());

            // Animate the puppet
            local result = Puppet.PlayMotion(puppet, motion);

            // havent changed sound schemas, so just overrode this .wav
            Sound.PlaySchemaAmbient(0, "bas0101b");
        } else {
            print("No puppet!");
        }
    }
}

class FacePuppet extends SqRootScript
{
    function OnMotionStart() {
        print(message().message);
        // this message doesnt get sent??
        SetData("MotionStarted", GetTime());
    }

    function OnMotionEnd() {
        print(message().message);
        local started = (IsDataSet("MotionStarted") ? GetData("MotionStarted") : 0);
        local ended = GetTime();
        local duration = (ended - started);
        if (duration >= 0.01) {
            local puppeteer = LinkDest(Link.GetOne("~ControlDevice", self));
            if (puppeteer != 0) {
                PostMessage(puppeteer, "TurnOff");
            }
        }
    }
}
