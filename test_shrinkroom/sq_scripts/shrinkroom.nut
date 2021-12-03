class AttachToPlayer extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("Shrink", 3.0);
        }
    }

    function OnTimer() {
        if (message().name=="Shrink") {
            StartShrinking();
        }
    }

    function StartShrinking() {
        // Start the tweq
        Property.Set(self, "StTweqScale", "AnimS", 3); // On|Reverse

        // DetailAttachement always tracks rotation, but with one frame
        // of lag. So we make do with PhysAttach and no rotation tracking.
        //
        // So, this is trying to resolve the problem of the room's pivot
        // being the point it shrinks around _and_ its position, by spawning
        // an anchor object that the room gets attached to. This doesn't
        // work as desired, however! There is still a jump when the room
        // attaches to the anchor point that is (when spawned) in front of
        // the player's eyes. Maybe this is just me calculating the
        // relative positions wrongly; or maybe it is me misunderstanding
        // the problem??
        //
        // One approach to fixing this would be to have a separate object
        // for each wall, and then each wall could be physattached to the
        // player and its center of shrinking would be just fine. But that
        // doesn't have quite the same 'falling out of reality' feeling.
        //
        // (A completely different trippy effect that a proxy could do is
        // a hall that tweqscales to get _longer_ as you walk along it!)
        //
        local player = ObjID("Player");
        local anchor = Object.Create("fnord");
        local anchorOffset = vector(-4.0,0.0,-2.0);
        local anchorPos = Object.ObjectToWorld(player, anchorOffset);
        Property.Set(anchor, "Position", "Location", anchorPos);
        Property.SetSimple(anchor, "RenderType", 1); // None
        if (false) {
            // To make the anchor visible:
            Property.SetSimple(anchor, "ModelName", "flashbom");
            Property.SetSimple(anchor, "RenderType", 2); // Unlit
        }
        Property.Set(anchor, "PhysType", "Type", "Sphere");
        Property.Set(anchor, "PhysDims", "Size", vector());
        Property.Set(anchor, "PhysControl", "Controls Active", 24); // Location|Rotation
        Property.SetSimple(anchor, "CollisionType", 0); // None
        // Link the anchor to the player:
        local link;
        local relPos = vector();
        local relFacing = vector();
        Object.CalcRelTransform(anchor, player, relPos, relFacing, 0, 0); // RelObject
        link = Link.Create("PhysAttach", anchor, player);
        LinkTools.LinkSetData(link, "Offset", relPos);
        // And link the room to the anchor:
        Object.CalcRelTransform(anchor, self, relPos, relFacing, 0, 0); // RelObject
        link = Link.Create("DetailAttachement", self, anchor);
        LinkTools.LinkSetData(link, "Type", "Object");
        print("relPos: " + relPos);
        LinkTools.LinkSetData(link, "rel pos", relPos);
        LinkTools.LinkSetData(link, "rel rot", relFacing);
    }
}
