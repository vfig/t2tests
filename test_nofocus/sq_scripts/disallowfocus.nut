class DisallowFocus extends SqRootScript {
    /* The only capability flag that is actually checked by the engine is
     * kDrkInvCapWorldFocus. So scripts cannot allow/disallow world frobs,
     * inv cycling, or inv frobs--only world focus. */
    function OnSim() {
        /* This capability is NOT automatically reset when leaving game mode
         * or starting game mode. So we need to make sure that we allow Garrett
         * to look at things again!! */
        print("> allow world focus");
        DrkInv.CapabilityControl(eDrkInvCap.kDrkInvCapWorldFocus, eDrkInvControl.kDrkInvControlOn);
    }

    function OnFrobWorldEnd() {
        print("> disallow world focus");
        DrkInv.CapabilityControl(eDrkInvCap.kDrkInvCapWorldFocus, eDrkInvControl.kDrkInvControlOff);
    }
}
