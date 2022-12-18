class BBBurpWhenSurprised extends SqRootScript
{
    function OnAlertness() {
        local hitpoints = GetProperty("HitPoints");
        local from = message().oldLevel;
        local to = message().level;
        if (to==3 || (to==2 && from==0)) {
            // Don't want to burp if we've just been killed.
            if (hitpoints <= 0) return;
            // Burp to launch a defensive stench cloud.
            //
            // This will still fire if we were blackjacked from behind though,
            // and that's fine: it'll teach you not to mistreat baby burricks!
            if (HasProperty("StTweqEmit")) {
                SetProperty("StTweqEmit", "AnimS", TWEQ_AS_ONOFF);
            }
        }
    }
}

class ForceFleeExpiry extends SqRootScript
{
    /*
    A fleeing AI can sometimes get stuck trying to path to a flee point,
    and the Flee goal doesn't let them give up until they reach it. So this
    script checks every IDLE_PERIOD seconds to see if the AI is fleeing. If
    they are, we forcibly expire their AIFleeDest link after EXPIRE_PERIOD
    seconds. This will stop them fleeing, and return them to regularly
    scheduled AI behaviour (which of course can include fleeing again if the
    conditions are present).
    */

    IDLE_PERIOD = 5.0;
    EXPIRE_PERIOD = 20.0;

    function OnBeginScript() {
        SetOneShotTimer("ForceFleeExpiry", IDLE_PERIOD, false);
    }

    function OnTimer() {
        if (message().name=="ForceFleeExpiry") {
            local scheduleExpiry = false;
            local link = Link.GetOne("AIFleeDest", self);
            if (link) {
                local forceLinkExpiry = message().data;
                if (forceLinkExpiry) {
                    LinkTools.LinkSetData(link, "Reached", true);
                    LinkTools.LinkSetData(link, "Expiration", 0);
                } else {
                    scheduleExpiry = true;
                }
            }
            SetOneShotTimer("ForceFleeExpiry",
                (scheduleExpiry? EXPIRE_PERIOD : IDLE_PERIOD), scheduleExpiry);
        }
    }
}

class BBFleeToPatrol extends SqRootScript
{
    function OnMotherMoved() {
        Link.DestroyMany("AIFleeTo", self, 0);
        local point0 = message().data;
        local point1 = message().data2;
        local point2 = message().data3;
        if (point0) Link.Create("AIFleeTo", self, point0);
        if (point1) Link.Create("AIFleeTo", self, point1);
        if (point2) Link.Create("AIFleeTo", self, point2);
    }
}

class BBHopping extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            SetData("BBHoppingTimer", 0);
            HopLater();
        }
    }

    function OnAlertness() {
        if (message().level > message().oldLevel
        && message().level >= 2) {
            // stop hopping right now
            Object.RemoveMetaProperty(self, "M-HoppingBriefly");
        }
    }

    function OnAIModeChange() {
        // when dead, stop trying to hop.
        if (message().mode == eAIMode.kAIM_Dead) {
            Object.RemoveMetaProperty(self, "M-Hopping");
        }
    }

    function OnTimer() {
        if (message().name=="BBHopping") {
            local isHopping = Object.HasMetaProperty(self, "M-HoppingBriefly");
            if (! isHopping) {
                // only allowed to hop when carefree
                local alert = AI.GetAlertLevel(self);
                if (alert<=1) {
                    // start hopping
                    Object.AddMetaProperty(self, "M-HoppingBriefly");
                }
            } else {
                // stop hopping
                Object.RemoveMetaProperty(self, "M-HoppingBriefly");
            }
            HopLater();
        }
    }

    function HopLater() {
        local rand = Data.RandFlt0to1();
        local isHopping = Object.HasMetaProperty(self, "M-HoppingBriefly");
        local period;
        if (isHopping) {
            // hopping is energy intensive, stop after a short time
            period = 2.0 + rand*3.0;
        } else {
            // but hopping is fun, so start again soon!
            period = 3.0 + rand*7.0;
        }
        local timer = GetData("BBHoppingTimer");
        if (timer != 0) KillTimer(timer);
        timer = SetOneShotTimer("BBHopping", period);
        SetData("BBHoppingTimer", timer);
    }
}