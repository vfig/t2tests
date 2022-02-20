class ElevPatrol extends SqRootScript {
    function StartPatrolling() {
        if (! Object.HasMetaProperty(self, "M-DoesPatrol")) {
            Object.AddMetaProperty(self, "M-DoesPatrol");
        }
    }

    function StopPatrolling() {
        if (Object.HasMetaProperty(self, "M-DoesPatrol")) {
            Object.RemoveMetaProperty(self, "M-DoesPatrol");
        }
    }

    function OnResumePatrolling() {
        local trol = 0;
        foreach (link in Link.GetAll("ScriptParams", self)) {
            local data = LinkTools.LinkGetData(link, "");
            if (data=="ResumePatrol") {
                trol = LinkDest(link);
            }
        }
        Link.DestroyMany("ScriptParams", self, 0);
        
        Object.Teleport(self, vector(), vector(), self); // HACK?

        if (trol) {
            if (! Link.AnyExist("AICurrentPatrol", self)) {
                print("Creating AICurrentPatrol to "+trol);
                Link.Create("AICurrentPatrol", self, trol);
            } else {
                print("HUH??? AICurrentPatrol already exists!");
            }
            StartPatrolling();
        }
    }

    function OnPatrolPoint() {
        print(message().message + " on " + message().to + " trol " + message().patrolObj);
        local trol = message().patrolObj;
        if (trol) {
            local terrPtLink = Link.GetOne("Route", trol);
            local nextTrolLink = Link.GetOne("AIPatrol", trol);
            if (terrPtLink && nextTrolLink) {
                local terrPt = LinkDest(terrPtLink);
                local nextTrol = LinkDest(nextTrolLink);
                // Abort current patrol
                StopPatrolling();
                local current = Link.GetOne("AICurrentPatrol", self);
                if (current) {
                    print("Current patrol is: "+LinkDest(current));
                //     print("Destroying current patrol to: "+LinkDest(current));
                //     Link.Destroy(current);
                }

                // Current patrol _will_ be destroyed before next tick, so lets
                // use a different link to track it.
                print("Creating ScriptParams link to "+nextTrol);
                local link = Link.Create("ScriptParams", self, nextTrol);
                LinkTools.LinkSetData(link, "", "ResumePatrol");

                print("Creating ScriptParams link to "+terrPt);
                local link = Link.Create("ScriptParams", self, terrPt);
                LinkTools.LinkSetData(link, "", "NotifyMe");

                // // Prepare for resuming
                // Link.Create("AICurrentPatrol", self, nextTrol);
                // Tell the elevator to move
                print("Sending TurnOn to: "+terrPt);
                SendMessage(terrPt, "TurnOn");
            } else if (terrPtLink) {
                print(trol+" has Route link to TerrPt, but is missing AIPatrol link to where to resume patrol.");
            } else if (nextTrolLink) {
                print(trol+" has AIPatrol link to resume patrol, but is missing Route link to TerrPt.");
            }
        }
    }

    function OnElevatorStarting() {
        print(message().message + " on " + message().to + " from " + message().from);
        SendMessage(self, "StopPatrolling");
    }

    function OnElevatorStopping() {
        print(message().message + " on " + message().to + " from " + message().from);
        SendMessage(self, "StartPatrolling");
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

class AIPatrolTerrPt extends SqRootScript {
    function OnMessage() {
        print(Object.GetName(self)+": "+message().message);
    }

    function OnWaypointReached() {
        print(Object.GetName(self)+": "+message().message);

        foreach (link in Link.GetAll("~ScriptParams", self)) {
            local data = LinkTools.LinkGetData(link, "");
            print("TerrPt has '"+data+"' link from "+LinkDest(link));
            if (data=="NotifyMe") {
                print("Should notify: "+LinkDest(link)+" "+Object.GetName(LinkDest(link)));
                SendMessage(LinkDest(link), "ResumePatrolling");
            }
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
