class BurrickPuppetteer extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            PostMessage(self, "TurnOn");
        }
    }

    function OnTurnOn() {
        // Pull the motion name from the "AI: Motion Tags"
        // property. It's abusing the property, but since the
        // pupetteer isn't an AI, it doesn't matter.
        local sender = message().from;
        local motion = Property.Get(sender, "AI_MotTags");
        SetData("CurrentMotion", motion);
        PlayMotion(motion);
    }

    function OnTurnOff() {
        local start_time = GetData("MotionStart").tofloat();
        local duration = (GetTime() - start_time);
        //print("Duration: " + duration);
        // Loop the motion if its more than a couple frames
        if (duration > 0.035) {
            PlayMotion(GetData("CurrentMotion"));
        }
    }

    function PlayMotion(index) {
        local puppet = LinkDest(Link.GetOne("ControlDevice", self));
        if (puppet != 0) {
            // Teleport the puppet back to our position (so motion offsets don't accumulate)
            Object.Teleport(puppet, vector(), vector(), self);

            // Get the motion name
            local motion = GetData("CurrentMotion");

            // Display which motion we're playing
            //local message = motion;
            //print("CurrentMotion: "+message);
            //DarkUI.TextMessage(message, 0xFFFFFF, 30000);

            SetData("MotionStart", GetTime());

            // Animate the puppet
            local result = Puppet.PlayMotion(puppet, motion);
        } else {
            print("No puppet!");
        }
    }
}

class BurrickPuppet extends SqRootScript
{
    function OnMotionStart() {
        // this message doesnt get sent??
        SetData("MotionStarted", GetTime());
    }

    function OnMotionEnd() {
        local started = (IsDataSet("MotionStarted") ? GetData("MotionStarted") : 0);
        local ended = GetTime();
        local duration = (ended - started);
        if (duration >= 0.01) {
            local puppeteer = LinkDest(Link.GetOne("~ControlDevice", self));
            if (puppeteer != 0) {
                PostMessage(puppeteer, "TurnOff");
            }
        }
    }
}

class BurrickConversation extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            // Pull the motion name from the "AI: Motion Tags"
            // property. It's abusing the property, but since the
            // pupetteer isn't an AI, it doesn't matter.
            //
            // Property.Set() for conversation fields doesn't work
            // for anything other than the first set of field (because
            // the field names are identical). But in this case it is
            // the first set of fields we want to change.
            local tags = GetProperty("AI_MotTags");
            if (tags!=null && tags!="") {
                Property.Set(self, "AI_Converation", "   Argument 3", tags);
            }
            PostMessage(self, "TurnOn");
        }
    }

    function OnTurnOn() {
        AI.StartConversation(self);
    }
}

class BurrickActor extends SqRootScript
{
    function OnConversationDone() {
        local link = Link.GetOne("~AIConversationActor", self);
        if (link) {
            local conv = LinkDest(link);
            // Our motion may have moved or turned us, so we want
            // to reset our position again.
            Object.Teleport(self, vector(), vector(), conv);
            PostMessage(conv, "TurnOn");
        }
    }
}

class BBFleeFromPlayer extends SqRootScript
{
    function OnAlertness() {
        local from = message().oldLevel;
        local to = message().level;
        if (to==3 || (to==2 && from==0)) {
            // Kick off the emit tweq (launch a stench cloud)
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
        print("New flee points: "+point0+", "+point1+", "+point2);
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
        print(GetTime()+"|"+self+": "+message().name);
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