/*
On the first TurnOn, find DetailAttached objects,
and start flowing them (dynamically) towards the target's
joints. Once an object gets within range of the target
joint, DetailAttach it. When all objects have been
attached to the target, send ParticleFlowDone to the
target and TurnOn along outgoing ControlDevice links.

The target must be linked from this object with a ScriptParams
link, with its value set to "ParticleFlowTgt".

TODO: this is _not_

*/
class ParticleFlow extends SqRootScript {
    particles = null;
    target = 0;
    flowSpeed = 3.0;
    flowInterval = 0.16;
    //flowInterval = 0.5;
    flowEndDelay = 1.5;

    function OnTurnOn() {
        if (IsDataSet("IsComplete")) return;
        if (IsDataSet("IsActive")) return;
        SetData("IsActive", true);

        FindTarget();
        if (target==0) {
            print("ERROR: ParticleFlow: no target found.");
            SetData("IsComplete", true);
            return;
        }

        FindParticles(true);
        if (particles.len()==0) {
            print("ERROR: ParticleFlow: no particles found.");
            SetData("IsComplete", true);
            return;
        }

        Flow();
    }

    function OnTimer() {
        if (message().name == "ParticleFlow") {
            Flow();
        } else if (message().name=="ParticleFlowEnd") {
            FlowEnd();
        }
    }

    function FindTarget() {
        if (target!=0) return target;
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="PFTarget") {
                target = LinkDest(link);
                return target;
            }
        }
        return 0;
    }

    function FindParticles(firstTime=false) {
        if (particles!=null) return particles;
        local foundParticles = [];
        foreach (link in Link.GetAll("ScriptParams", self)) {
            local data = LinkTools.LinkGetData(link, "");
            if (data.find("PFJoint")==null) continue;
            local obj = LinkDest(link);
            local joint = data.slice(7).tointeger();
            foundParticles.append({ obj=obj, joint=joint, marker=0, delta=vector() });
        }
        foreach (p in foundParticles) {
            foreach (link in Link.GetAll("ScriptParams", p)) {
                local data = LinkTools.LinkGetData(link, "");
                if (data!="PFMarker") continue;
                p.marker = LinkDest(link);
                break;
            }
        }
        if (foundParticles.len()==0) {
            if (firstTime)
                particles = DetachParticles();
        } else {
            particles = foundParticles;
        }
        return particles;
    }

    function CreateTargetMarker(obj, joint) {
        local m = Object.Create("Marker");
        local link = Link.Create("DetailAttachement", m, target);
        LinkTools.LinkSetData(link, "rel pos", vector());
        LinkTools.LinkSetData(link, "rel rot", vector());
        LinkTools.LinkSetData(link, "Flags", 2 /* No Joint Rot */);
        LinkTools.LinkSetData(link, "Type", 2 /* Joint */);
        LinkTools.LinkSetData(link, "joint", joint);
        local link = Link.Create("ScriptParams", obj, m);
        LinkTools.LinkSetData(link, "", "PFMarker");
        return m;
    }

    function DetachParticles() {
        local foundParticles = [];
        local killLinks = [];
        foreach (link in Link.GetAll("~DetailAttachement", self)) {
            local obj = LinkDest(link);
            if (! Property.Possessed(obj, "ParticleGroup")) continue;
            local attachType = LinkTools.LinkGetData(link, "Type");
            if (attachType!=2 /* Joint */) continue;
            local joint = LinkTools.LinkGetData(link, "joint");
            if (joint<=0 /* N/A */) continue;
            local marker = CreateTargetMarker(obj, joint);
            foundParticles.append({ obj=obj, joint=joint, marker=marker, delta=vector() });
            killLinks.append(link);
        }
        if (foundParticles.len()==0) return null;
        foreach (link in killLinks) {
            LinkTools.LinkSetData(link, "Flags", 1 /* No Auto Delete */);
            Link.Destroy(link);
        }
        foreach (p in foundParticles) {
            local link = Link.Create("ScriptParams", self, p.obj);
            LinkTools.LinkSetData(link, "", "PFJoint"+p.joint);
            Object.AddMetaProperty(p.obj, "M-ParticleFlowMoving");
            Property.Add(p.obj, "PhysType");
            SendMessage(p.obj, "TurnOn");
        }
        return foundParticles;
    }

    function Flow() {
        FindTarget();
        FindParticles();

        local waitForParticlesCount = particles.len();
        local maxDistance = 0.0;
        foreach (p in particles) {
            local objPos = Object.Position(p.obj);
            local markerPos = Object.Position(p.marker);
            p.delta = markerPos-objPos;
            local sign = (p.delta.z<0.0)? -1 : 1;
            p.delta.z = sign*pow(abs(p.delta.z) 1.5);
            local distance = p.delta.Length();
            if (distance>maxDistance)
                maxDistance = distance;
        }
        foreach (i, p in particles) {
            local distance = p.delta.Length();
            if (distance<(flowInterval*flowSpeed) || p.marker==0) {
                Object.Teleport(p.obj, vector(), vector(), p.marker);
                Physics.SetVelocity(p.obj, vector());
                waitForParticlesCount -= 1;
            } else {
                local n = p.delta.GetNormalized();
                local v = vector();
                Physics.GetVelocity(p.obj, v);
                local nv = n*flowSpeed*(distance/maxDistance);
                Physics.SetVelocity(p.obj, nv);
           }
        }

        if (waitForParticlesCount==0) {
            SetOneShotTimer("ParticleFlowEnd", flowEndDelay);
        }

        if (particles==null || particles.len()==0 || waitForParticlesCount==0) {
            SetData("IsComplete", true);
            SendMessage(target, "ParticleFlowDone");
            SendMessage(target, "PhantomBegin");
            SendMessage(target, "TurnOn");
            Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            return;
        }

        SetOneShotTimer("ParticleFlow", flowInterval);
    }

    function FlowEnd() {
        FindTarget();
        FindParticles();

        foreach (p in particles) {
            Object.Destroy(p.marker);
            Link.Destroy(Link.GetOne("ScriptParams", self, p.obj));
            Physics.SetVelocity(p.obj, vector());
            Object.RemoveMetaProperty(p.obj, "M-ParticleFlowMoving");
            Property.Remove(p.obj, "PhysType");
            local link = Link.Create("DetailAttachement", p.obj, target);
            LinkTools.LinkSetData(link, "rel pos", vector());
            LinkTools.LinkSetData(link, "rel rot", vector());
            LinkTools.LinkSetData(link, "Flags", 2 /* No Joint Rot */);
            LinkTools.LinkSetData(link, "Type", 2 /* Joint */);
            LinkTools.LinkSetData(link, "joint", p.joint);
            SendMessage(p.obj, "TurnOff");
        }
        particles = null;
    }
}
