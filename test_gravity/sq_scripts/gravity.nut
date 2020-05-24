// Stolen from https://github.com/whoopdedo/tnhscript/blob/9af57b02fb4de3b8cc8652a353be6b9f24d17c18/src/tnhScript.nut#L320

/********************
 * ZeroGravRoom
 * 
 * Sets the player's gravity to zero when entered. Sets it to 100% on exit.
 * 
 * This is a copy of the script with the same name from System Shock 2.
 * 
 * Messages: PlayerRoomEnter, PlayerRoomExit
 */
class ZeroGravRoom extends SqRootScript {
    function OnPlayerRoomEnter() {
        local move_obj = message().MoveObjId
        Property.Set(move_obj, "PhysAttr", "Gravity %", 0.0)
        Property.Set(move_obj, "PhysAttr", "Base Friction", 1.0)
    }

    function OnPlayerRoomExit() {
        local move_obj = message().MoveObjId
        local room_obj = message().ToObjId
        local gravity = 100.0
        if (Property.Possessed(room_obj, "RoomGrav"))
            gravity = Property.Get(room_obj, "RoomGrav")
        Property.Set(move_obj, "PhysAttr", "Gravity %", gravity)
    }
}
