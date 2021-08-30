/* Okay, this is all a very dodgy way to go about it! Aim for more sanity:

    a. the ai needs to stop patrolling when it hits the embark point.
    b. it needs to TurnOn (or frob) another object there.
    c. then it needs to wait until the elevator reaches a stop TerrPt;
            (maybe elevator OnStopping can broadcast another message to all objects contacting it?)
    d. then ai resumes patrolling, but must pick the disembark point!

    could get more complex with the ai summoning the elevator, too...

    good news is this first experiment was really to see if ais could ride
    elevators, and they absolutely can! just need to be careful with distances
    from terrain so the pathfinding doesnt fail (the debug views of pathfinding
    are helpful there!)
*/

class TrigTrolPtReached extends SqRootScript
{
    function OnPatrolPointReached() {
        print(message().message + " on " + message().to + " from " + message().from);
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }
}

class TrolStopPatrolling extends SqRootScript
{
    function OnPatrolPointReached() {
        print(message().message + " on " + message().to + " from " + message().from);
        SendMessage(message().from, "StopPatrolling");
    }
}

class TrolStartPatrolling extends SqRootScript
{
    function OnPatrolPointReached() {
        print(message().message + " on " + message().to + " from " + message().from);
        SendMessage(message().from, "StartPatrolling");
    }
}

class NotifyTrolPoints extends SqRootScript
{
    function OnPatrolPoint() {
        print(message().message + " on " + message().to + " from " + message().from);
        local trol = message().patrolObj;
        if (trol) {
            SendMessage(trol, "PatrolPointReached");
        }
    }

    function OnStartPatrolling() {
        print(message().message + " on " + message().to + " from " + message().from);
        if (! Object.HasMetaProperty(self, "M-DoesPatrol")) {
            Object.AddMetaProperty(self, "M-DoesPatrol");
            print("Added M-DoesPatrol");
        } else {
            print("Already got M-DoesPatrol on " + self);
        }
    }

    function OnStopPatrolling() {
        print(message().message + " on " + message().to + " from " + message().from);
        if (Object.HasMetaProperty(self, "M-DoesPatrol")) {
            Object.RemoveMetaProperty(self, "M-DoesPatrol");
            print("Removed M-DoesPatrol");
        } else {
            print("No M-DoesPatrol on " + self);
        }
    }
}

/*********************************************************/

class DynamicLiftControl extends SqRootScript {
    function OnTurnOn() {

        // look, just dont frob the buttons while the elevator is moving, okay?
        // i cant be held responsible!

        // Find the lift, the start and end points, and all the midpoints:
        local links = Link.GetAll("ScriptParams", self);
        local lift = 0;
        local startpt = 0;
        local stoppt = 0;
        local midpts = [];
        local allpts = [];
        foreach (link in links) {
            local data = LinkTools.LinkGetData(link, "");
            local o = LinkDest(link);
            if (data=="Lift") {
                lift = o;
            } else if (data=="Start") {
                startpt = o;
                allpts.push(o);
            } else if (data=="Stop") {
                stoppt = o;
                allpts.push(o);
            } else {
                midpts.push(o);
                allpts.push(o);
            }
        }

        // Destroy all TPath links between the points:
        local links_to_destroy = [];
        foreach (pt in allpts) {
            local links = Link.GetAll("TPath", pt);
            foreach (link in links) {
                links_to_destroy.push(link);
            }
        }
        foreach (link in links_to_destroy) {
            Link.Destroy(link);
        }
        // // And the next path the lift is going to:
        // local link = Link.GetOne("TPathNext", lift);
        // if (link) Link.Destroy(link);

        // Create a random chain between the start and the stop
        local a = startpt;
        local nextpt = 0;
        if (midpts.len()>0) {
            nextpt = midpts[0];
        } else {
            nextpt = stoppt;
        }
        srand(GetTime()*1000000000);
        while (midpts.len()>0) {
            local i = rand() % midpts.len();
            local b = midpts[i];
            midpts.remove(i);
            print("TPath: " + a + "->" + b);
            local link = Link.Create("TPath", a, b);
            LinkTools.LinkSetData(link, "Speed", 5.0);
            a = b;
        }
        print("TPath (last): " + a + "->" + stoppt);
        local link = Link.Create("TPath", a, stoppt);
        LinkTools.LinkSetData(link, "Speed", 5.0);

        //// i am not at all sure if TPathNext is needed, but it certainly
        //// doesnt seem to make much difference!
        // print("TPathNext: " + lift + "->" + nextpt);
        // Link.Create("TPathNext", lift, nextpt);

        // Finally, call the elevator!
        local lift_pos = Object.Position(lift);
        local start_pos = Object.Position(startpt);
        local stop_pos = Object.Position(stoppt);
        local start_dist = (lift_pos-start_pos).Length();
        local stop_dist = (lift_pos-stop_pos).Length();
        if (start_dist<stop_dist) {
            SendMessage(stoppt, "TurnOn");
        } else {
            SendMessage(startpt, "TurnOn");
        }
    }
}
