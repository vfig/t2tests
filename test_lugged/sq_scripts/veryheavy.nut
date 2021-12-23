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

class VeryLight extends SqRootScript {
    function OnContained() {
        if (Object.InheritsFrom(message().container, "Avatar")) {
            const gravityAmount = 0.1;
            local player = message().container;
            if (message().event==eContainsEvent.kContainAdd) {
                Sound.PlaySchemaAmbient(self,"garlift");
                Physics.SetGravity(player, gravityAmount);
            } else if (message().event==eContainsEvent.kContainRemove) {
                Sound.PlaySchemaAmbient(self,"gardrop");
                Physics.SetGravity(player, 1.0);
            }
        }
    }
}

class VeryBuoyant extends SqRootScript {
    /* When this object is picked up by the player, the player will have
     * difficulty swimming downward, but will swim upward very quickly. It
     * does this by altering the player's `Physics>Attributes>Density`.
     *
     * The player can still get quite deep on their initial plunge into the
     * water when they jump in, however. So plan for your level design to
     * mitigate that.
     */
    function OnContained() {
        if (Object.InheritsFrom(message().container, "Avatar")) {
            // This value is extremely finicky: 0.7 makes it pretty much
            // impossible to swim down; 0.8 is hard to distinguish from the
            // original swimming behviour! 0.77 feels decent.
            const itIsMyDensity = 0.77;
            local player = message().container;
            if (message().event==eContainsEvent.kContainAdd) {
                Sound.PlaySchemaAmbient(self,"garlift");
                if (! IsDataSet("VeryBuoyantDensity")) {
                    local density = Property.Get(player, "PhysAttr", "Density");
                    SetData("VeryBuoyantDensity", density);
                }
                Property.Set(player, "PhysAttr", "Density", itIsMyDensity);
            } else if (message().event==eContainsEvent.kContainRemove) {
                Sound.PlaySchemaAmbient(self,"gardrop");
                local density = GetData("VeryBuoyantDensity");
                if (density==null) density = 1.0;
                Property.Set(player, "PhysAttr", "Density", density);
            }
        }
    }
}
