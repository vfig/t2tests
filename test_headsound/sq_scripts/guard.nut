function PreFilterMessage(message) {
    local guard = Object.Named("Thron");
    local schema = Object.Named("sg1a0");
    // Phooey. the "schema message" functionality (see the property ive thrown
    // onto the sg1a0 archetype) isn't actually implemented.
    if (message.to == guard || message.from == guard
        || message.to == schema || message.from == schema
        || message.message == "BadSmell")
    {
        print("=> " + message.message);
    }
    // return 'true' if message should be intercepted and not sent to the target script instance
    return false;
}

class DebugGuard extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            print("DebugGuard starting!");
        } else {
            print("DebugGuard ending!");
        }
    }
}

class TestSound0 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // doesnt work?
        local s = "PlayAtLocation";
        print(s);
        local pos = Object.Position(self);
        DarkUI.TextMessage(s, 0, 250);
        Sound.PlayAtLocation(0, "sg1a0mu1b", pos);
    }
}

class TestSound1 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // stereo pans according to camera
        local s = "PlayAtObject";
        print(s);
        DarkUI.TextMessage(s, 0, 250);
        Sound.PlayAtObject(0, "sg1a0mu1b", self);
    }
}

class TestSound2 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // doesnt work?
        local s = "Play";
        print(s);
        DarkUI.TextMessage(s, 0, 250);
        Sound.Play(0, "sg1a0mu1b");
    }
}

class TestSound3 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // unpositioned
        local s = "PlayAmbient";
        print(s);
        DarkUI.TextMessage(s, 0, 250);
        Sound.PlayAmbient(0, "sg1a0mu1b");
    }
}

class TestSound4 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // stereo pans according to camera
        local s = "PlaySchemaAtLocation";
        print(s);
        DarkUI.TextMessage(s, 0, 250);
        local pos = Object.Position(self);
        Sound.PlaySchemaAtLocation(0, "sg1a0", pos);
    }
}

class TestSound5 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // stereo pans according to camera
        local s = "PlaySchemaAtObject";
        print(s);
        DarkUI.TextMessage(s, 0, 250);
        Sound.PlaySchemaAtObject(0, "sg1a0", self);
    }
}

class TestSound6 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // unpositioned
        local s = "PlaySchema";
        print(s);
        DarkUI.TextMessage(s, 0, 250);
        Sound.PlaySchema(0, "sg1a0");
    }
}

class TestSound7 extends SqRootScript
{
    function OnFrobWorldEnd() {
        // unpositioned
        local s = "PlaySchemaAmbient";
        print(s);
        DarkUI.TextMessage(s, 0, 250);
        Sound.PlaySchemaAmbient(0, "sg1a0");
    }
}

