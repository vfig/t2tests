class StunOnCollide extends SqRootScript {

    function OnBeginScript() {
        // Ask to be notified when I collide with anything
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnEndScript() {
        // Clean up: make sure I won't be notified anymore.
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnPhysCollision() {
        local obj = message().collObj;

        //ShockAI.Stun(obj, null, "Blinded 0, Stalled 0", 4.0);


        // Only try to stun AIs, not anything else.
        // (If you prefer, you could instead use obj.InheritsFrom() to only try to stun Creatures, or Humans, or any other archetype.)
        if (false && Property.Possessed(obj, "AI")) {
            // Remember who we're stunning so we can unstun them later.
            SetData("StunTarget", obj);

            // Also remember their motion tags (if any) so we can restore them.
            if (Property.Possessed(obj, "AI_MotTags")) {
                local tags = Property.Get(obj, "AI_MotTags");
                SetData("StunOrigMotTags", tags);
            }

            print("STUNNING: " + obj);

            // Now stun them: stop what they're doing, give them appropriate motion tags, and politely inform them.
            local duration = 4.0;
            local tags = "Blinded 0, Stalled 0";
            AI.ClearGoals(obj);
            Property.SetSimple(obj, "AI_MotTags", tags);
            SendMessage(obj, "Stun");

            // Now set a timer so we can un-stun the AI after four seconds
            SetOneShotTimer("Stun", duration);

            // Teleport myself to 0,0,0 to get out of the way (don't want to be slain just yet, cause I'm waiting for a timer!)
            Object.Teleport(self, vector(), vector());

            // Become non-physical so we don't have any more collisions
            Reply(ePhysMessageResult.kPM_NonPhys);

        } else {
            // We hit something else, so just get slain without trying to stun anything.
            Reply(ePhysMessageResult.kPM_Slay);
        }
    }

    function OnTimer() {
        if (message().name == "Stun") {
            if (IsDataSet("StunTarget")) {
                local obj = GetData("StunTarget");

                print("UNSTUNNING: " + obj);

                if (IsDataSet("StunOrigMotions")) {
                    local tags = GetData("StunOrigMotTags");
                    Property.SetSimple(obj, "AI_MotTags", tags);
                } else {
                    Property.Remove(obj, "AI_MotTags");
                }

                SendMessage(obj, "Unstun");

                Object.Destroy(self);   
            }
        }
    }
}