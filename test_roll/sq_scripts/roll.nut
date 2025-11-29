// TODO: PROBLEMS
//    - cant reliably detect if standing on OBB/Sphere/Sphere Hat object [for crouch override]
//    - cant detach from ladders/ropes [for crouch override]
//    - cant handle "hold crouch" variant [for crouch override]
//    - cant detect key _held_ properly (just get repeat pings)
//          - _could_ have script that adds metaprop to player if not present,
//            or pings player to postpone removal of metaprop if present; but
//            the delay and repeat rate is likely from the user's settings in the os??

// TODO:
//    - all the TODOs below.
//    - damage reduction calculation not yet implemented
//    - could have a roll button that can be used obviously when landing,
//      but also when running/sprinting?
//    - could maybe have a sprint button?? with stamina ofc to prevent too much
//      abuse; would it be a hold or a toggle?
//    - see bug note in bnd.ini (BUG? commands after first dont show their string in the ui)

class CmdRoll extends SqRootScript
{
    function OnPing() {
        print("Ping CmdRoll"
            +" data:"+(message().data==null? "null" : message().data)
            +" data2:"+(message().data==null? "null" : message().data2)
            +" data3:"+(message().data==null? "null" : message().data3));
        SendMessage("Player", "CmdRoll", message().data, message().data2, message().data3)
    }
}

class Roll extends SqRootScript
{
    DEBUG_LOG_COLLISIONS = true;
    DEBUG_LOG_CONTACTS = false;

    ROLL_VELOCITY_BOOST = 20.0;

    m_footContacts = null; // Foot tracks terrain and object contacts.
    m_shinContacts = null; // Shin tracks only object contacts (for sphere hats mostly).

    constructor() {
        m_footContacts = {};
        m_footContacts["terrain"] <- 0;
        m_shinContacts = {};
    }

    function OnBeginScript() {
        // TODO: try reading config for ROLL_VELOCITY_BOOST alteration?

        if (Object.InheritsFrom(self, "Avatar")
        || self==Object.Named("Player")) {
            ActReact.SubscribeToStimulus(self, "BashStim");
            Physics.SubscribeMsg(self,
                 ePhysScriptMsgType.kCollisionMsg
                |ePhysScriptMsgType.kContactMsg);

            // Are we currently in a roll.
            if (! IsDataSet("IsRolling")) SetData("IsRolling", FALSE);
            // Time roll was pressed (while not grounded).
            if (! IsDataSet("PressTime")) SetData("PressTime", 0.0);
            // Time last BashStim came in.
            if (! IsDataSet("BashTime")) SetData("BashTime", 0.0);
            // Intensity of last BashStim.
            if (! IsDataSet("BashIntensity")) SetData("BashIntensity", 0.0);

            // TODO: remove.
            SetOneShotTimer("DumpGrounded", 2.0);
        }
    }

    function OnEndScript() {
        if (Object.InheritsFrom(self, "Avatar")
        || self==Object.Named("Player")) {
            ActReact.UnsubscribeToStimulus(self, "BashStim");
            Physics.UnsubscribeMsg(self,
                 ePhysScriptMsgType.kCollisionMsg
                |ePhysScriptMsgType.kContactMsg);
        }
    }

    // TODO: remove
    function DumpVelocity() {
        local vel = vector();
        Physics.GetVelocity(self, vel);
        print("  Z vel:"+vel.z);
    }

    function OnCmdRoll() {
        // TODO: check if controls are locked out, e.g. from remote camera or NoMove() script api?

        switch (DarkGame.GetPlayerMode()) {
        // Do a roll if grounded in these modes:
        case ePlayerMode.kPM_Stand:
        case ePlayerMode.kPM_BodyCarry: // TODO: allow roll in BodyCarry and force body drop?
        case ePlayerMode.kPM_Crouch:
        case ePlayerMode.kPM_Jump:
            // NOTE: After mantling a Sphere Hat object, you often remain in
            //       Jump mode, which is (at least partly) why you cant crouch
            //       until you move enough to step and go back to Stand mode.
            print("Stand/BodyCarry/Crouch/Jump: -> roll (if grounded).");
            HandleCmdRoll();
            break;

        // Do nothing for other modes:
        case ePlayerMode.kPM_Swim:
        case ePlayerMode.kPM_Climb:
        case ePlayerMode.kPM_Slide:
        case ePlayerMode.kPM_Dead:
            print("Swim/Climb/Slide/Dead: ignoring roll.");
            break;
        }
    }

    function HandleCmdRoll() {
        // TEMP: experimenting with midair rolls?
        if (TRUE|| IsGrounded()) {
            // Do a roll now.

            // Get both our XY velocity and XY forward vector.
            local vel = vector();
            Physics.GetVelocity(self, vel);
            local fallVelocity = vel.z;
            vel.z = 0.0;
            local forward = Object.ObjectToWorld(self, vector(1,0,0))-Object.Position(self);
            forward.z = 0.0;
            forward.Normalize();

            // TODO: probably use z velocity to distinguish between a fall and
            //       a jump, and only allow a midair roll from lowish z velocities;
            //       high z velocities should instead trigger a roll on landing.

            // Boost velocity so we can roll from standing, or roll much
            // farther while running.
            print("vel mag:"+vel.Length());
            local boost = ROLL_VELOCITY_BOOST;
            if (IsGrounded()) {
            } else {
                // TODO: falling velocity conversion?
                // Reduce boost if rolling in midair (no ground to push off)
                boost *= 0.5;
            }
            vel += (forward*boost)
            print("boost mag:"+vel.Length());

            DoRoll(vel);
        } else {
            // If we land imminently, we will do a roll then.
            SetData("PressTime", GetTime());
            DumpVelocity();
        }
    }

    function DoRoll(velocity) {
        if (GetData("IsRolling")) return;
        // Doing a roll is too dangerous for the player, so we have a stunt
        // double do it. (We can't actually manage the player's physics nor
        // camera adequately, hence this fakery.)
        local o = Object.Create("StuntDouble");

        // If we start the stunt double exactly at our origin, it hits belly-
        // high objects that we _could_ roll under if we are too close to them
        // when starting the roll. So we start the stunt double from a point
        // relative to our foot instead (so its stance-independent). We add
        // a tiny bit of extra z clearance in case the foot is just under
        // something.

        // TODO: if we are in midair though, we probably want to position the
        //       stunt double relative to our head/camera so that we can
        //       dive roll onto tables and other lowish surfaces!

        // TODO: also support sideways/diagonal rolls if the player is strafing!
        //       (which means the player facing we restore to will not always
        //       be the same direction as the roll velocity).

        local relpos = vector();
        local relfac = vector();
        Object.CalcRelTransform(self, self, relpos, relfac,
            4 /* RelSubPhysModel */, 1 /* PLAYER_FOOT */);
        local footpos = Object.ObjectToWorld(self, -relpos);
        local radius = Property.Get(o, "PhysDims", "Radius 1");
        local spawnpos = footpos+vector(0,0,radius+0.05);
        local spawnfac = Object.Facing(self);
        Object.Teleport(o, spawnpos, spawnfac, 0);
        // BUG: Physics.ValidPos() does not check against objects, so will allow
        //      rolling through doors!
        if (Physics.ValidPos(o)) {
            Physics.ControlCurrentRotation(o);
            Physics.SetVelocity(o, velocity);
            print("ROLL BEGIN. velocity:"+velocity);
            SetData("IsRolling", TRUE);
            SendMessage(o, "RollBegin");
        } else {
            print("Invalid position for StuntDouble; aborting roll.");
            Sound.PlaySchema(0, "gardrop");
            Object.Destroy(o);
        }
    }

    function OnRollComplete() {
        SetData("IsRolling", FALSE);

        // TODO: transfer remaining velocity to player?
        local remainingVel = message().data;
        print("ROLL COMPLETE. remainingVel:"+remainingVel);
        // TODO: make sure this goes in the right direction!!
        //Physics.SetVelocity("Player", vector(-15,0,0));

    }

    function OnTimer() {
        if (message().name=="DumpGrounded") {
            local isGrounded = IsGrounded();
            local isTerrainOnly = IsGrounded(true);
            print(": grounded: "+(isTerrainOnly? "TERRAIN" : isGrounded? "OBJECT" : "-"));
            if (DEBUG_LOG_CONTACTS) {
                print("    Foot:");
                foreach (key,value in m_footContacts) {
                    print("      "+key+":"+value);
                }
                print("    Shin:");
                foreach (key,value in m_shinContacts) {
                    print("      "+key+":"+value);
                }
            }
            SetOneShotTimer("DumpGrounded", 2.0);
        }
    }

    function OnBashStimStimulus() {
        print("BashStim"
            +" time:"+GetTime()
            +" intensity:"+message().intensity
            +" sensor:"+message().sensor
            +" source:"+desc(message().source));
        DumpVelocity();

        // TODO: distinguish HOW we are getting bashed, i.e.
        //       if source==0 and velocity<(-15? 0?), then it
        //       is fall damage.
        local timeElapsed = (GetTime()-GetData("PressTime"));
        print("  Time since last crouch press: "+timeElapsed);
        // TODO: tune press window
        // TODO: maybe allow slight window after hitting ground?
        if (0.0<=timeElapsed && timeElapsed<=0.2) {
            print("  ************ roll ************");
            // TODO: check for space to roll?
            // TODO: do a roll
        } else {
            // TODO: stochastic round?
            local damage = floor(message().intensity+0.5);
            Damage.Damage(self, 0, damage, (message().stimulus).tointeger());
        }
    }

    function OnDamage() {
        print("Damage"
            +" time:"+GetTime()
            +" kind:"+message().kind
            +" damage:"+message().damage
            +" culprit:"+message().culprit);
    }

    function OnPhysCollision() {
        if (DEBUG_LOG_COLLISIONS) {
            if (message().Submod==1  // PLAYER_FOOT
            ||message().Submod==3    // PLAYER_KNEE
            ||message().Submod==4) { // PLAYER_SHIN
                local typeString = "unknown";
                switch(message().collType) {
                case ePhysCollisionType.kCollNone: typeString = "none"; break;
                case ePhysCollisionType.kCollTerrain: typeString = "terrain"; break;
                case ePhysCollisionType.kCollObject: typeString = "object"; break;
                }
                print(message().message
                    +" bodypart:"+message().Submod
                    +" time:"+GetTime()
                    +" type:"+typeString
                    +" obj:"+desc(message().collObj)
                    +" submod:"+message().collSubmod
                    +" momentum:"+message().collMomentum
                    +" normal.z:"+message().collNormal.z
                    +" pos:"+message().collPt);
            }
        }
    }

    function TrackFootContact(createContact) {
        // Track terrain face / object contacts. Call this only from
        // PhysContactCreate/PhysContactDestroy handlers.
        // We need to track the shin as well as the foot, because when mantling
        // onto sphere hat objects, sometimes it is only the shin that is in
        // contact with the object (even when you can do the crouch dance).
        local isFoot = (message().Submod==1); // PLAYER_FOOT
        local isShin = (message().Submod==4); // PLAYER_SHIN
        if (! isFoot && ! isShin) return;

        local key;
        switch (message().contactType) {
        case ePhysContactType.kContactFace:
            // Not interested in terrain contacts for anything except the foot.
            if (! isFoot) return;
            key = "terrain";
            break;
        case ePhysContactType.kContactSphere:
        case ePhysContactType.kContactSphereHat:
        case ePhysContactType.kContactOBB:
            local objid = (message().contactObj).tointeger();
            local submod = (message().contactSubmod).tointeger();
            key = ""+objid+","+submod;
            break;
        default: return;
        }

        local table = (isFoot? m_footContacts : m_shinContacts);
        local count = 0;
        if (table.rawin(key)) {
            count = table.rawget(key);
        }
        count += (createContact? 1 : -1);
        if (count<0) { count = 0; print("### Count underflow for "+key); }
        if (count>0 || key=="terrain") {
            table.rawset(key, count);
        } else {
            table.rawdelete(key);
        }
    }

    function IsGrounded(terrainOnly=false) {
        local terrainContacts = (m_footContacts.rawget("terrain")>0);
        local otherContacts = (m_footContacts.len()>1) || (m_shinContacts.len()>0);
        if (terrainOnly)
            return terrainContacts;
        else
            return (terrainContacts || otherContacts);
    }

    function OnPhysContactCreate() {
        TrackFootContact(true);

        if (DEBUG_LOG_CONTACTS) {
            if (message().Submod==1  // PLAYER_FOOT
            ||message().Submod==3    // PLAYER_KNEE
            ||message().Submod==4) { // PLAYER_SHIN
                local typeString = "unknown";
                switch (message().contactType) {
                case ePhysContactType.kContactNone: typeString = "none"; break;
                case ePhysContactType.kContactFace: typeString = "face"; break;
                case ePhysContactType.kContactEdge: typeString = "edge"; break;
                case ePhysContactType.kContactVertex: typeString = "vertex"; break;
                case ePhysContactType.kContactSphere: typeString = "sphere"; break;
                case ePhysContactType.kContactSphereHat: typeString = "spherehat"; break;
                case ePhysContactType.kContactOBB: typeString = "obb"; break;
                }
                print(message().message
                    +" bodypart:"+message().Submod
                    +" time:"+GetTime()
                    +" type:"+typeString
                    +" obj:"+desc(message().contactObj)
                    +" submod:"+message().contactSubmod);
            }
        }
    }

    function OnPhysContactDestroy() {
        TrackFootContact(false);

        if (DEBUG_LOG_CONTACTS) {
            if (message().Submod==1  // PLAYER_FOOT
            ||message().Submod==3    // PLAYER_KNEE
            ||message().Submod==4) { // PLAYER_SHIN
                local typeString = "unknown";
                switch (message().contactType) {
                case ePhysContactType.kContactNone: typeString = "none"; break;
                case ePhysContactType.kContactFace: typeString = "face"; break;
                case ePhysContactType.kContactEdge: typeString = "edge"; break;
                case ePhysContactType.kContactVertex: typeString = "vertex"; break;
                case ePhysContactType.kContactSphere: typeString = "sphere"; break;
                case ePhysContactType.kContactSphereHat: typeString = "spherehat"; break;
                case ePhysContactType.kContactOBB: typeString = "obb"; break;
                }
                print(message().message
                    +" bodypart:"+message().Submod
                    +" time:"+GetTime()
                    +" type:"+typeString
                    +" obj:"+desc(message().contactObj)
                    +" submod:"+message().contactSubmod);
            }
        }
    }
}

class PlayerRolling extends SqRootScript
{
    // TODO: do we still need this metaprop and script?
}

class RollStuntDouble extends SqRootScript
{
    DEBUG_NOATTACH = false;
    DEBUG_NOTELEPORT = false;
    DEBUG_NODESTROY = false;
    DEBUG_NOROLL = false;
    DEBUG_VISIBLEPARTS = false;

    function OnBeginScript() {
        if (DEBUG_VISIBLEPARTS)
            Property.SetSimple(self, "RenderAlpha", 0.25);
        else
            Property.SetSimple(self, "RenderType", 1); // Not Rendered
    }

    function OnRollBegin() {
        if (! DEBUG_NOTELEPORT) {
            DarkGame.PlayerMode(ePlayerMode.kPM_Crouch);
            DarkGame.NoMove(true);
        }

        // NOTE: Teleporting the player does not break contacts, so if the
        //       player is pressed up against an object, then rolls, the physics
        //       engine still thinks theyre pressed up against it after the
        //       teleport, and they cant then walk in that direction. VERY BAD!
        //
        //       However, a very handy side effect of Physics.SetVelocity() is
        //       that it breaks ALL terrain and object contacts! So we use it
        //       here not just to stop the player moving, but also for that
        //       side effect!
        Physics.SetVelocity("Player", vector());

        // TODO: unphysicalise the player (can we?) and DetailAttach them to
        //       the stunt double too. (and make them 100% transparent?)

        // NOTE: We can't remove PhysType from the player, because when adding
        //       it again, its just a default 1 big sphere, not the correct 5 submodels.
        Property.SetSimple("Player", "CollisionType", 0); // None
        //Property.Remove("Player", "PhysType");

        local spinner = Object.Create("fnord");
        Property.SetSimple(spinner, "ModelName", "axisjoints"); // has rotary joint
        if (DEBUG_VISIBLEPARTS)
            Property.SetSimple(spinner, "RenderType", 0); // Normal
        Object.Teleport(spinner, vector(), vector(), self);
        local link = Link.Create("DetailAttachement", spinner, self);
        LinkTools.LinkSetData(link, "rel pos", vector());
        LinkTools.LinkSetData(link, "rel rot", vector());
        Property.Add(spinner, "CfgTweqJoints");
        if (DEBUG_NODESTROY)
            Property.Set(spinner, "CfgTweqJoints", "Halt", TWEQ_STATUS_QUO);
        else
            Property.Set(spinner, "CfgTweqJoints", "Halt", TWEQ_HALT_SLAY);
        Property.Set(spinner, "CfgTweqJoints", "AnimC", TWEQ_AC_SIM);
        Property.Set(spinner, "CfgTweqJoints", "MiscC", 0);
        Property.Set(spinner, "CfgTweqJoints", "CurveC" 0);
        Property.Set(spinner, "CfgTweqJoints", "Primary Joint", 2);
        Property.Set(spinner, "CfgTweqJoints", "Joint2AnimC", TWEQ_AC_SIM);
        Property.Set(spinner, "CfgTweqJoints", "Joint2CurveC", 0);
        Property.Set(spinner, "CfgTweqJoints", "    rate-low-high2", vector(40.0,0,360));
        Property.Set(spinner, "StTweqJoints", "MiscS", 0);
        if (! DEBUG_NOROLL) {
            Property.Set(spinner, "StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
            Property.Set(spinner, "StTweqJoints", "Joint2AnimS", TWEQ_AS_ONOFF);
        }
        Property.Set(spinner, "Scripts", "Script 0", "RollSpinner");
        
        local anchor = Object.Create("fnord");
        Property.SetSimple(anchor, "ModelName", "waypt");
        if (DEBUG_VISIBLEPARTS)
            Property.SetSimple(anchor, "RenderType", 0); // Normal
        Object.Teleport(anchor, vector(), vector(), self);
        link = Link.Create("DetailAttachement", anchor, spinner);
        LinkTools.LinkSetData(link, "vhot/sub #", 6);
        LinkTools.LinkSetData(link, "Type", 4); // Subobject
        // TODO: offset for head location? this z offset is just me throwing numbers, its not quite the cam offset
        LinkTools.LinkSetData(link, "rel pos", vector(0,0,1.25));
        LinkTools.LinkSetData(link, "rel rot", vector());

        link = Link.Create("ScriptParams", self, anchor);
        LinkTools.LinkSetData(link, "", "StuntDouble");
        PostMessage(self, "AttachCamera");
    }

    function OnAttachCamera() {
        if (DEBUG_NOATTACH)
            return;
        local link = Link.GetOne("ScriptParams", self);
        if (link) {
            local anchor = LinkDest(link);
            Camera.StaticAttach(anchor);
            PostMessage(self, "AttachCamera");
        }
    }

    function OnRollComplete() {
        print(message().message);
        local pos;
        local link = Link.GetOne("ScriptParams", self);
        if (link) {
            local anchor = LinkDest(link);
            pos = Object.Position(anchor)+vector(0,0,0.25);
        } else {
            // Hack, in case anchor is gone, to keep player out of the ground.
            pos = Object.Position(self)+vector(0,0,2);
        }
        local fac = Object.Facing("Player"); // TODO: self?
        if (! DEBUG_NOTELEPORT) {
            // TODO: set position instead of teleport so as not to break awareness.
            Object.Teleport("Player", pos, fac, 0);
            // TODO: see if there is room to stand; stay crouched if not.
            DarkGame.PlayerMode(ePlayerMode.kPM_Stand);
            DarkGame.NoMove(false);
        }
        if (! DEBUG_NOATTACH)
            Camera.ForceCameraReturn();

        local vel = vector();
        Physics.GetVelocity(self, vel);
        // TODO: if this works, save/load the CollisionType instead of hardcoding.
        Property.SetSimple("Player", "CollisionType", 0x1); // Bounce
        SendMessage("Player", "RollComplete", vel);

        if (! DEBUG_NODESTROY)
            Object.Destroy(self);
    }
}

class RollSpinner extends SqRootScript
{
    function OnSlain() {
        foreach (link in Link.GetAll("~ScriptParams")) {
            if (LinkTools.LinkGetData(link, "")=="StuntDouble") {
                SendMessage(LinkDest(link), "RollComplete");
                return;
            }
        }
        print("ERROR: Did not find stunt double ;_;");
    }
}

class DebugSpawnStuntDouble extends SqRootScript
{
    function OnTurnOn() {
        local o = Object.Create("StuntDouble");
        Object.Teleport(o, vector(), vector(), self);
        //Property.Set(o, "PhysState", "Rot Velocity", vector(0,-8,0));
        Physics.ControlCurrentRotation(o);
        // TODO: make sure this goes in the right direction!!
        Physics.SetVelocity(o, vector(-30,0,0));
    }
}

class DebugSprint extends SqRootScript
{
    // 
    function OnTurnOn() {
        print("DebugSprint: "+message().message);
        DrkInv.AddSpeedControl("Sprint", 1.8, 1.0);
    }

    function OnTurnOff() {
        print("DebugSprint: "+message().message);
        DrkInv.RemoveSpeedControl("Sprint");
    }
}
