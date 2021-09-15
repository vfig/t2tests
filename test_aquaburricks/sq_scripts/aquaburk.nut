class AquaBurrick extends SqRootScript
{
    function OnMediumTransition() {
        print("transitioned from medium "
            + message().nFromType
            + " to "
            + message().nToType);

        // Air:
        if (message().nToType==1) {
            if (Object.HasMetaProperty(self, "M-AquaBurrickInWater")) {
                Object.RemoveMetaProperty(self, "M-AquaBurrickInWater");
                print("removed the metaprop");
            }
        }
        // Water:
        else if (message().nToType==2) {
            if (! Object.HasMetaProperty(self, "M-AquaBurrickInWater")) {
                Object.AddMetaProperty(self, "M-AquaBurrickInWater");
                print("added the metaprop");
            }
        }
    }
}
