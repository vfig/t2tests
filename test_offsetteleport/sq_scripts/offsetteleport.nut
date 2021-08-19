class OffsetTeleportTrap extends SqRootScript
{
    function GetScriptParamsObj(from, to, data) {
        local links = Link.GetAll("ScriptParams", from, to);
        foreach (link in links) {
            local link_data = LinkTools.LinkGetData(link, "");
            if (link_data == data) {
                return LinkDest(link);
            }
        }
        return 0;
    }

    function OnTurnOn() {
        local ref = GetScriptParamsObj(self, 0, "OTTRelativeTo");
        local params = userparams();
        local offset = vector();
        if ("OTTOffsetX" in params) offset.x = params.OTTOffsetX.tofloat();
        if ("OTTOffsetY" in params) offset.y = params.OTTOffsetY.tofloat();
        if ("OTTOffsetZ" in params) offset.z = params.OTTOffsetZ.tofloat();
        if (ref) {
            local pos = Object.Position(ref);
            local fac = Object.Facing(ref);
            Object.Teleport(self, pos+offset, fac, 0);
            Physics.ControlCurrentPosition(self);
        }
    }
}
