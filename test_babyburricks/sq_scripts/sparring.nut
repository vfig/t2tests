class Sparring extends SqRootScript
{
    /* BUGS:
        1. they keep trying to do this even if they are KOd or dead. they cant
           act then, but will stand up and try to.
        2. they should not be trying to do this when their target is KOd, or
           dead, or not nearby.
        3. if their partner is not available, but the target dummy is, then
           they should maybe wail on that instead?
        4. i currently have Broadcasts fully disabled on these guards so their
           combat shouts dont alert nearby ai to come and investigate. but
           this is bad for gameplay involving the player. also, the sound of
           their swords clashing still brings other ais sometimes (and should
           not be happening with wooden swords). solution: give these guards
           a custom voice set with combat shouts that dont carry combat value.
    */

    function FindTarget() {
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local link_data = LinkTools.LinkGetData(link, "");
            if (link_data == "SparAttack") {
                return LinkDest(link);
            }
        }
        return 0;
    }

    function SparAttack(target) {
        if (! Link.AnyExist("AITarget", self)) {
            // An AITarget link can even force an AI to attack a friendly,
            // as long as they're in combat mode. Thanks Firemage!
            SetProperty("AI_Mode", eAIMode.kAIM_Combat);
            Link.Create("AITarget", self, target);
        }
    }

    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("SparAttack", 0.5+Data.RandFlt0to1());
        }
    }

    function OnTimer() {
        if (message().name=="SparAttack") {
            local target = FindTarget();
            if (target) {
                SparAttack(target);
                // Every two seconds, the AI will re-evaluate its targets. When
                // that happens, it will see that its target is on the same team,
                // and so not valid, and will remove it. So we need to repeatedly
                // re-add it. We do so with a little randomness, so that the two
                // guards won't be synchronized.
                SetOneShotTimer("SparAttack", 0.5+Data.RandFlt0to1());
            }
        }
    }
}
