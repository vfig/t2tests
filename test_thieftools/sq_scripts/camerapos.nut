class FixedCameraPos extends SqRootScript
{
    function OnSim() {
        // Attaching OnSim doesnt work (presumably because it gets reattached
        // to the player moments later).
        PostMessage(self, "FixCameraPos");
    }

    function OnFixCameraPos() {
        Camera.StaticAttach(self);
    }
}
