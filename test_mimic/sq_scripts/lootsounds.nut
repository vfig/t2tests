// Based on stock LootSounds scripts, but suppresses loot sounds
// when the global "SuppressLootSounds" is true. We use a global
// because this suppression is only meant for inter-frame use as
// scripts transfer inventory around. We use the same name as the
// stock script so that this one will override the stock script.
//
g_SuppressLootSounds <- false;

EnableLootSounds <- function(enable) {
    g_SuppressLootSounds = !enable;
}

class LootSounds extends SqRootScript {
    function OnContained() {
        if (message().event!=eContainsEvent.kContainRemove
        && message().container==Object.Named("Player")
        && GetTime()>0.1
        && !g_SuppressLootSounds)
        {
            local schem = 0;
            if (Object.InheritsFrom(self, "IsLoot"))
                schem = Object.Named("pickup_loot");
            else
                schem = Object.Named("pickup_power");
            if (schem!=0)
                Sound.PlaySchemaAmbient(self, schem);
        }
    }
}
