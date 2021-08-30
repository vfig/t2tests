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
