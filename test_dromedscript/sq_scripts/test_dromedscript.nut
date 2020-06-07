// Put this script on an obj named 'EditorCreateWaterObj'
// Run it with 'script_test EditorCreateWaterObj'
//
class EditorCreateWater extends SqRootScript {
    function OnTest() {
        print("EditorCreateWater OnTest");

        local editorMode = Version.IsEditor();
        if (editorMode == 0) {
            print("In the game");
        } else if (editorMode == 1) {
            print("In the editor, in edit mode");
        } else if (editorMode == 2) {
            print("In the editor, in game mode");
        }

        if (editorMode == 1) {
            local arch = Object.Named("WaterCrystal");
            local obj = Object.BeginCreate(arch);
            Object.Teleport(obj, vector(3,0,0), vector());
            Property.SetSimple(obj, "StackCount", 100);
            Object.EndCreate(obj);
            print("Just created a stack of 100 water arrows!!");
        
            // But Camera service doesn't return the editor camera position, just zeroes :(
            // And of course there's no way to find out the selected brush position either.
            // print("Camera is at: " + Camera.GetPosition() + " facing: " + Camera.GetFacing());
        }
    }
}
