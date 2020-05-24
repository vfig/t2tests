class TestRotateVismeter extends SqRootScript
{
    angles = vector(0, 60, 0);

    function OnTurnOn()
    {
        SetOneShotTimer("hack", 0.05);
    }

    function OnTimer()
    {
        SetOneShotTimer("hack", 0.05);

        Debug.Command("set vismeter_ang " + angles.x + " " + angles.y + " " + angles.z);
        angles.z += 1;
        if (angles.z >= 360) {
            angles.z -= 360;
        }
    }
}