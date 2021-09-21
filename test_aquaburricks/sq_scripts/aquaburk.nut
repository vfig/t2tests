class AquaBurrick extends SqRootScript
{
    function OnMediumTransition() {
        print("transitioned from medium "
            + message().nFromType
            + " to "
            + message().nToType);

        // Air:
        if (message().nToType==1) {
            if (Object.HasMetaProperty(self, "M-AquaBurrickInWater")) {
                Object.RemoveMetaProperty(self, "M-AquaBurrickInWater");
                print("removed the metaprop");
            }
        }
        // Water:
        else if (message().nToType==2) {
            if (! Object.HasMetaProperty(self, "M-AquaBurrickInWater")) {
                Object.AddMetaProperty(self, "M-AquaBurrickInWater");
                print("added the metaprop");
            }
        }
    }
}

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
