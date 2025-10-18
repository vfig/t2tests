/* Put this on an AI. Checks periodically if they are fleeing, and if they
 * are, will make them stop if they go too far from what they were fleeing
 * from.
 *
 * Design Note parameters [default value]:
 *
 *      LimitFleeDistance [200]       Will stop fleeing if this distance or further.
 *      LimitFleeInterval [4700]      Check this often (ms) if we are fleeing.
 */
class LimitFlee extends SqRootScript
{
    kMinDistance = 200;
    kIntervalMs = 4700;

    function OnBeginScript() {
        local minDist = userparam("LimitFleeDistance", kMinDistance);
        local intervalMs = userparam("LimitFleeInterval", kIntervalMs);
        SetOneShotTimer("LimitFlee", (intervalMs*0.001));
    }

    function OnTimer() {
        if (message().name=="LimitFlee") {
            if (IsBeyondMinDistance()) {
                Link.DestroyMany("AIFleeSource", self.tostring(), "@object");
                Link.DestroyMany("AIFleeDest", self.tostring(), "@object");
            }
            local intervalMs = userparam("LimitFleeInterval", kIntervalMs);
            SetOneShotTimer("LimitFlee", (intervalMs*0.001));
        }
    }

    function IsBeyondMinDistance() {
        if (Link.AnyExist("AIFleeDest", self)) {
            local source = 0;
            local link = Link.GetOne("AIFleeSource", self);
            if (link==0) {
                // If we don't know what we are fleeing, assume it's the player.
                source = Object.Named("Player");
            } else {
                source = LinkDest(link);
            }
            local d = (Object.Position(self) - Object.Position(source));
            local dist = d.Length();
            local minDist = userparam("LimitFleeDistance", kMinDistance);
            return (dist > minDist);
        }
        return false;
    }

    function userparam(name, defaultValue) {
        if (name in userparams()) {
            return userparams()[name];
        } else {
            return defaultValue;
        }
    }
}


/* Put this on an AI. Will heal them to full HP when they stop fleeing.
 * Requires NewDark 1.28 or later.
 */
class HealAfterFlee extends SqRootScript {
    function OnBeginScript() {
        // Sanity check against 1.27, cause I still use that!
        if ("Listener" in getroottable()) {
            Listener.SubscribeLink(self, self, "AIFleeDest",
                 eRelationListenMsg.kListenLinkDeath);
        } else {
            print("ERROR: HealAfterFlee requires NewDark 1.28 or later.");
            DarkUI.TextMessage("ERROR: HealAfterFlee requires NewDark 1.28 or later.", 0xff);
        }
    }

    function OnEndScript() {
        // Sanity check against 1.27, cause I still use that!
        if ("Listener" in getroottable()) {
            Listener.UnsubscribeLink(self, self, "AIFleeDest");
        }
    }

    function OnLinkNotify() {
        // BUG: in NewDark 1.28, LinkNotify gets an sTraitNotifyMsg message
        // instead of a sLinkNotifyMsg. Hence this try/catch spam to more
        // gracefully handle the missing fields.

        if (message().type!=eRelationListenMsg.kListenLinkDeath) return;

        try {
            if (message().flavor!=linkkind("AIFleeDest")) return;
        } catch (err) {
            // 1.28 throws. We carry on assuming this is the right link flavor.
        }

        try {
            if (message().source!=self) return;
        } catch (err) {
            // 1.28 throws. We carry on assuming the link is from us.
        }

        // Time to heal!
        local maxHP = HasProperty("MAX_HP")? GetProperty("MAX_HP") : 100;
        SetProperty("HitPoints", maxHP);
    }
}
