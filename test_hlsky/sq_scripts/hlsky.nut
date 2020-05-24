class ChangeTimeOfDay extends SqRootScript
{
    function OnTurnOn() {
        // Time of day is stored as an hour number.
        local timeofday = GetData("TimeOfDay");
        // Starting time of day is 20:00.
        if (timeofday == null) { timeofday = 20; }
        // Advance the hour; cycle round if after 22:00 (cause I only put three setups in here).
        timeofday = timeofday + 1;
        if (timeofday > 22) { timeofday = 20; }
        SetData("TimeOfDay", timeofday);
        // Trigger the appropriate marker.
        if (timeofday == 20) {
            SendMessage(Object.Named("TimeOfDay07"), "TurnOn");
        }
        else if (timeofday == 21) {
            SendMessage(Object.Named("TimeOfDay08"), "TurnOn");
        }
        else if (timeofday == 22) {
            SendMessage(Object.Named("TimeOfDay09"), "TurnOn");
        }
    }
}

class TimeOfDay09 extends SqRootScript
{
    function OnTurnOn() {
        Engine.SetEnvMapZone(0, "env\\hlsky09");
        local skylight07 = Object.Named("SkyLight07");
        local skylight08 = Object.Named("SkyLight08");
        local skylight09 = Object.Named("SkyLight09");
        SendMessage(skylight07, "TurnOff");
        SendMessage(skylight08, "TurnOff");
        SendMessage(skylight09, "TurnOn");
    }
}

class TimeOfDay07 extends SqRootScript
{
    function OnTurnOn() {
        Engine.SetEnvMapZone(0, "env\\hlsky07");
        local skylight07 = Object.Named("SkyLight07");
        local skylight08 = Object.Named("SkyLight08");
        local skylight09 = Object.Named("SkyLight09");
        SendMessage(skylight07, "TurnOn");
        SendMessage(skylight08, "TurnOff");
        SendMessage(skylight09, "TurnOff");
    }
}

class TimeOfDay08 extends SqRootScript
{
    function OnTurnOn() {
        Engine.SetEnvMapZone(0, "env\\hlsky08");
        local skylight07 = Object.Named("SkyLight07");
        local skylight08 = Object.Named("SkyLight08");
        local skylight09 = Object.Named("SkyLight09");
        SendMessage(skylight07, "TurnOff");
        SendMessage(skylight08, "TurnOn");
        SendMessage(skylight09, "TurnOff");
    }
}

class TimeOfDay09 extends SqRootScript
{
    function OnTurnOn() {
        Engine.SetEnvMapZone(0, "env\\hlsky09");
        local skylight07 = Object.Named("SkyLight07");
        local skylight08 = Object.Named("SkyLight08");
        local skylight09 = Object.Named("SkyLight09");
        SendMessage(skylight07, "TurnOff");
        SendMessage(skylight08, "TurnOff");
        SendMessage(skylight09, "TurnOn");
    }
}
