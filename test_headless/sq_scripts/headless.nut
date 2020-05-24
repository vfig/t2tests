/*
class Headless extends SqRootScript
{
    // so, these callbacks only fire for stuff we tell things to do :(
    // and we only get all the motion flags for AIs with the "Puppet" property,
    // which then don't act as AIs :(

    function OnMotionStart() {
        print("Motion: " + message().MotionName
            + ", action: " + message().ActionType
            + ", flag: " + message().FlagValue);
    }

    function OnMotionEnd() {
        print("Motion: " + message().MotionName
            + ", action: " + message().ActionType
            + ", flag: " + message().FlagValue);
    }

    function OnMotionFlagReached() {
        print("Motion: " + message().MotionName
            + ", action: " + message().ActionType
            + ", flag: " + message().FlagValue);
    }

    function OnSoundDone() {
        print("Sound: " + message().name
            + ", at: " + message().coordinates
            + ", target: " + message().targetObject);
    }

    function OnSchemaDone() {
        print("Schema: " + message().name
            + ", at: " + message().coordinates
            + ", target: " + message().targetObject);
    }
}

class TestButton1 extends SqRootScript
{
    function OnTurnOn() {
        print("TestButton1");
        local player = Object.Named("Player");
        local headless = Object.Named("Headless1");
        // Sound.PlayAtObject(headless, "kar1603I", player);
        local result = Puppet.PlayMotion(headless, "BH413265");
        print("Result: " + result);
    }
}
*/