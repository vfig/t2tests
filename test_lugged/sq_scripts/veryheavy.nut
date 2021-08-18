class VeryHeavy extends SqRootScript {
    /* When this object is picked up by the player, the player will walk slower
     * and turn slower (just like the stock script Lugged), and also jump less
     * high. The effects are removed when this object is dropped.
     *
     * If you have slowfall potions or gravshafts or other scripts that set
     * the player's gravity, they will not play nicely with this!
     */
    function OnContained() {
        if (Object.InheritsFrom(message().container, "Avatar")) {
            const walkFactor = 0.6;
            const turnFactor = 0.9;
            const jumpFactor = 0.5;
            local player = message().container;
            if (message().event==eContainsEvent.kContainAdd) {
                Sound.PlaySchemaAmbient(self,"garlift");
                DrkInv.AddSpeedControl("VeryHeavyCarry", walkFactor, turnFactor);
                Physics.SetGravity(player, 1.0/jumpFactor);
            } else if (message().event==eContainsEvent.kContainRemove) {
                Sound.PlaySchemaAmbient(self,"gardrop");
                DrkInv.RemoveSpeedControl("VeryHeavyCarry");
                Physics.SetGravity(player, 1.0);
            }
        }
    }
}
