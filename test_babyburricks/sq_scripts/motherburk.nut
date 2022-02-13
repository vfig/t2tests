class MotherBurrick extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            MakeBabiesFollow();
        }
    }

    function MakeBabiesFollow() {
        local links;
        // Find all the attached watchpoints
        links = Link.GetAll("~DetailAttachement", self);
        local watchPoints = [];
        foreach (link in links) {
            local o = LinkDest(link);
            if (Property.Possessed(o, "AI_WtchPnt")) {
                print("Found watch point "+o);
                watchPoints.append(o);
            }
        }
        // Find all our babies
        links = Link.GetAll("Owns", self);
        local babies = [];
        foreach (link in links) {
            local o = LinkDest(link);
            if (Object.InheritsFrom(o, "BabyBurrick")) {
                print("Found baby "+o);
                babies.append(o);
            }
        }
        // Link each baby to each watchpoint
        foreach (baby in babies) {
            foreach (pt in watchPoints) {
                print("Linking "+baby+" to "+pt);
                Link.Create("AIWatchObj", baby, pt);
            }
        }
    }
}

class PatrollingMother extends SqRootScript
{
    function OnPatrolPoint() {
        // Collect up the patrol point we just reached, the next one we are
        // going to, and a patrol point after that (if there is one).
        local point0 = message().patrolObj;
        local point1 = 0;
        local point2 = 0;
        local link = Link.GetOne("AICurrentPatrol", self);
        if (link) point1 = LinkDest(link);
        if (point1) {
            link = Link.GetOne("AIPatrol", point1);
            if (link) point2 = LinkDest(link);
        }
        // Notify each of our children about all three points.
        local links = Link.GetAll("Owns", self);
        foreach (link in links) {
            SendMessage(LinkDest(link), "MotherMoved", point0, point1, point2);
        }
    }
}
