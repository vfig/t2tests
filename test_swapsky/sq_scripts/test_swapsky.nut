class TestSwapSky extends SqRootScript
{
    function OnTurnOn() {
        Engine.SetEnvMapZone(0, "env\\skycube2");
    }

    function OnTurnOff() {
        Engine.SetEnvMapZone(0, "env\\skycube");
    }
}
