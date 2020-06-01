class StartsOff extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SendMessage(self, "TurnOff");
        }
    }
}

class AutoTorch extends SqRootScript {
    function OnIgniteStimStimulus() {
        local intensity = message().intensity;
        print("IgniteStim on " + self + ": " + intensity);
        if (intensity >= 10 && intensity <= 100) {
            SendMessage(self, "TurnOn");
        }
    }

    function OnDouseStimStimulus() {
        local intensity = message().intensity;
        print("DouseStim on " + self + ": " + intensity);
        if (intensity >= 10 && intensity <= 100) {
            SendMessage(self, "TurnOff");
        }
    }
}
