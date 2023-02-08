class MotionItem extends SqRootScript
{
    function TriggerConversation(conv, concept, soundTags, motionTags) {
        if (conv==0) return;
        if (! Property.Possessed(conv, "AI_Converation")) return;
        SendMessage(conv, "TurnOff");
        // TODO: maybe need to wait a frame?
        Property.Set(conv, "AI_Converation", "Conversation: Action 0", 2); // Play sound/motion(Sound Concept,Sound Tags,Motion Tags)
        Property.Set(conv, "AI_Converation", "   Argument 1", concept);
        Property.Set(conv, "AI_Converation", "   Argument 2", soundTags);
        Property.Set(conv, "AI_Converation", "   Argument 3", motionTags);
        SendMessage(conv, "TurnOn");
    }

    function OnFrobInvEnd() {
        local conv = Object.Named("MotionConvo");
        local motion = userparams().Motion;
        if (motion==null || motion=="") return;
        TriggerConversation(conv, "", "", motion);
    }
}

class MotionSetContainer extends SqRootScript
{
    function CreateItems(motionSet, arch) {
        // Spawn one instance of arch for each motion in motionSet.
        // Set its name, cycle order, and motion parameter.
        // Contain it, and track it with an Owns link.
        foreach (motionTag in motionSet) {
            local o = Object.Create(arch);
            Object.Teleport(o, vector(), vector(), self);
            Property.SetSimple(o, "InvCycleOrder", motionTag);
            Property.SetSimple(o, "GameName", "n: \""+motionTag+"\"");
            Property.SetSimple(o, "DesignNote", "Motion="+motionTag+";");
            Container.Add(o, self, eDarkContainType.kContainTypeGeneric, CTF_NONE);
            Link.Create("Owns", self, o);
        }
    }

    function OnSim() {
        if (message().starting) {
            // Spawn one item for each motion we have.
            local arch = Object.Named("ArchMotionItem");
            local groupName = userparams().MotionGroup;
            local index = userparams().MotionSet;
            if (arch==0) return;
            if (groupName==null) return;
            if (index==null) return;
            CreateItems(MOTIONS[groupName][index].tags, arch);
        }
    }

    function OnWorldSelect() {
        local text = userparams().MotionSetName;
        if (text!=null)
            DarkUI.TextMessage(text, 0, 1000000);
    }

    function OnWorldDeSelect() {
        DarkUI.TextMessage("", 0);
    }

    function OnFrobWorldEnd() {
        // Activate our joints.
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeJoints, eTweqDo.kTweqDoActivate);
    }

    function OnTweqComplete() {
        // If we are opening, give everything to the player.
        // If we are closing, take it all back.
        local opening = (message().Dir==eTweqDirection.kTweqDirForward);
        if (opening) {
            local player = Object.Named("Player");
            local link = Link.GetOne("Owns", self);
            local firstItem = link? LinkDest(link) : 0;
            Container.MoveAllContents(self, player, CTF_NONE);
            if (firstItem!=0)
                DarkUI.InvSelect(firstItem);
        } else {
            foreach (link in Link.GetAll("Owns", self)) {
                local o = LinkDest(link);
                Container.Add(o, self, 0, CTF_NONE);
            }
        }
    }
}

class MotionContainerSpawner extends SqRootScript
{
    function CreateContainer(groupName, index, name, arch) {
        // Spawn an instance of arch.
        // Set its visible name, cycle order, and motion parameter.
        // Contain it, and track it with an Owns link.
        local step = vector(2.0, 0.0, 0.0);
        local o = Object.Create(arch);
        Object.Teleport(o, step*index, vector(), self);
        local value = ("MotionGroup="+groupName+";"
            +"MotionSet="+index+";"
            +"MotionSetName="+name+";");
        print(value);
        Property.SetSimple(o, "DesignNote", value);
    }

    function OnSim() {
        if (message().starting) {
            // Spawn one container for each name.
            local arch = Object.Named("ArchMotionSetContainer");
            if (arch==0) return;
            local groupName = userparams().MotionGroup;
            if (groupName==null || groupName=="") return;
            foreach (index, group in MOTIONS[groupName]) {
                CreateContainer(groupName, index, group.name, arch);
            }
            Object.Destroy(self);
        }
    }
}
