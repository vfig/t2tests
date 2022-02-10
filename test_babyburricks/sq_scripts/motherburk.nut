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
        print("Patrol points: "+point0+", "+point1+", "+point2);
        // Notify each of our children about all three points.
        local links = Link.GetAll("Owns", self);
        foreach (link in links) {
            print("Notifying "+LinkDest(link));
            SendMessage(LinkDest(link), "MotherMoved", point0, point1, point2);
        }
    }
}
