/* Put the "AutoRoomAmbient" script on your Base Room archetype. Then on each
   concrete Room archetype where you want an ambience schema to automatically
   play, give it the `Room>Ambient` property, and set the `Schema Name` field
   to the schema that this room should play.

   The script will start and stop such schemas automatically as the player
   enters and leaves room brushes.

   The schemas will be played 'environmentally', so that the "Ambient" volume
   slider in the options menu controls them.
*/
class AutoRoomAmbient extends SqRootScript
{
    function GetSchema(room) {
        if (Property.Possessed(room, "Ambient")) {
            return Property.Get(room, "Ambient", "Schema Name");
        } else {
            return "";
        }
    }

    function OnPlayerRoomEnter() {
        local fromSchema = GetSchema(message().FromObjId);
        local toSchema = GetSchema(message().ToObjId);
        local player = message().MoveObjId;

        if (toSchema!=fromSchema) {
            if (Version.IsEditor()) {
                print("AutoRoomAmbient: "+fromSchema+" => "+toSchema);
            }
            if (fromSchema!="") {
                Sound.HaltSchema(player, fromSchema);
            }
            if (toSchema!="") {
                Sound.PlaySchemaAmbient(player, toSchema);
            }
        }
    }
}
