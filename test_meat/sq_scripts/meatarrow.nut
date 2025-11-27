class MeatCrystal extends SqRootScript
{
    function OnFrobWorldEnd() {
        print("frobber: "+message().Frobber);
        if (Object.InheritsFrom(message().Frobber, "Avatar")
        || message().Frobber==Object.Named("Player")) {
            local arrow = Object.Create("MeatArrow");
            if (HasProperty("StackCount")) {
                Property.CopyFrom(arrow, "StackCount", self);
            }
            Container.Add(arrow, message().Frobber);
        }
    }
}


enum eJoint {
    kHead           = 1,
    kNeck           = 2,
    kAbdomen        = 3,
    kButt           = 4,
    kLeftShoulder   = 5,
    kRightShoulder  = 6,
    kLeftElbow      = 7,
    kRightElbow     = 8,
    kLeftWrist      = 9,
    kRightWrist     = 10,
    kLeftFingers    = 11,
    kRightFingers   = 12,
    kLeftHip        = 13,
    kRightHip       = 14,
    kLeftKnee       = 15,
    kRightKnee      = 16,
    kLeftAnkle      = 17,
    kRightAnkle     = 18,
    kLeftToe        = 19,
    kRightToe       = 20,
    kTail           = 21,
}

class MeatConvert extends SqRootScript
{
    function SpawnMeat(arch, joint, loc, facing) {
        local marker = Object.Create("Marker");
        local link = Link.Create("DetailAttachement", marker, self);
        LinkTools.LinkSetData(link, "joint" joint);
        LinkTools.LinkSetData(link, "Type", 2); // Joint
        local meat = Object.Create(arch);
        Object.Teleport(meat, loc, facing, marker);
    }
    
    function OnMeatStimStimulus() {
        if (message().intensity>0.0) {
            local joints = [
                eJoint.kLeftElbow,
                eJoint.kRightElbow,
                eJoint.kLeftKnee,
                eJoint.kRightKnee,
                //eJoint.kAbdomen,
                eJoint.kHead,
            ];
            local archNames = [
                "MeatDeerLeg",
                "MeatDeerLeg",
                "MeatDeerLeg",
                "MeatDeerLeg",
                //"MeatDeerLeg",
                "MeatChicken",

            ];
            local relfacings = [
                vector(),
                vector(180,0,0),
                vector(270,0,180),
                vector(270,0,180),
                //vector(270,0,180),
                vector(),
            ];
            local relpos = vector();
            local relfac = vector();
            for (local i=0; i<joints.len(); ++i) {
                SpawnMeat(archNames[i], joints[i], vector(), relfacings[i]);
            }
            Object.Destroy(self);
        }
    }
}
