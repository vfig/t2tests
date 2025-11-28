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

class CmdCrouchRoll extends SqRootScript
{
    function OnPing() {
        print("Ping CmdCrouchRoll"
            +" data:"+message().data
            +" data2:"+message().data2
            +" data3:"+message().data3);
        SendMessage("Player", "ToggleCrouch", message().data, message().data2, message().data3)
    }
}

class Roll extends SqRootScript
{
    function OnBeginScript() {
        ActReact.SubscribeToStimulus(self, "BashStim");
        if (! IsDataSet("PressTime")) {
            SetData("PressTime", 0.0);
        }
    }

    function OnEndScript() {
        ActReact.UnsubscribeToStimulus(self, "BashStim");
    }

    function DumpVelocity() {
        local vel = vector();
        Physics.GetVelocity(self, vel);
        print("Z vel:"+vel.z);
    }

    function CheckGrounded() {
        // Get the foot position
        local foot_pos = vector();
        local foot_fac = vector();
        Object.CalcRelTransform(self, self, foot_pos, foot_fac, 4 /* RelSubPhysModel */, 1 /* PLAYER_FOOT */);
        foot_pos = Object.ObjectToWorld(self, -foot_pos);
        print("Our pos:"+Object.Position(self)+" foot_pos:"+foot_pos);
        // Cast down to see if we hit terrain, OBB, or Sphere/Sphere Hat object
        local hit_pos = vector();
        local hit_obj = object();
        // ARRRGH! Raycast is casting to the *object polygons*, not to the
        //         physics model! so this is not gonna reliably keep track of
        //         if we are on the ground or not :(
        local hit_type = Engine.ObjRaycast(
            foot_pos+vector(0,0,0.05),
            foot_pos-vector(0,0,0.05),
            hit_pos, hit_obj,
            2 /* return any hit object or terrain */,
            1 /* ignore mesh objects */,
            self /* ignore player */, 0);
        print("hit type:"+hit_type+" pos:"+hit_pos+" obj:"+hit_obj.tointeger());
        switch (hit_type) {
        case 0: // No hit
        case 3: // Mesh object
            return FALSE;
        case 1: // Terrain
        case 2: // Object
            return TRUE;
        }
    }

    function OnToggleCrouch() {
        // TODO: check if controls are locked out, e.g. from remote camera or NoMove() script api?
        switch (DarkGame.GetPlayerMode()) {
        case ePlayerMode.kPM_Stand:
        case ePlayerMode.kPM_BodyCarry:
            print("Stand/Carry: -> crouch.");
            HandleCrouch(TRUE);
            break;
        case ePlayerMode.kPM_Crouch:
            print("Crouch: -> stand up.");
            HandleCrouch(FALSE);
            break;
        case ePlayerMode.kPM_Swim:
            print("Swim: ignoring crouch.");
            break;
        case ePlayerMode.kPM_Climb:
            print("Climb: ignoring crouch.");
            // TODO: can we do a detach, if the config is set??
            print("crouch_unmount: "+Engine.BindingGetFloat("crouch_unmount"));
            // this is not sufficient to force a detach:
            //     DarkGame.PlayerMode(ePlayerMode.kPM_Stand);
            // this might be useful:
            //     Physics.GetClimbingObject(object climber, object & climbobj);
            break;
        case ePlayerMode.kPM_Slide:
            print("Slide: ignoring crouch.");
            break;
        case ePlayerMode.kPM_Jump:
            print("Jump: treat as -> stand up.");
            HandleCrouch(FALSE);
            break;
        case ePlayerMode.kPM_Dead:
            // Do nothing.
            print("Dead: ignoring crouch.");
            break;
        }
    }

    function HandleCrouch(crouch) {
        local isOnGround = CheckGrounded();
        print("isOnGround:"+isOnGround);
        DumpVelocity();

        if (isOnGround) {
            print("crouch: "+crouch);
            DarkGame.PlayerMode(crouch? ePlayerMode.kPM_Crouch : ePlayerMode.kPM_Stand);
        } else {
            SetData("PressTime", GetTime());
        }
    }

    function OnBashStimStimulus() {
        print("BashStim intensity:"+message().intensity
            +" sensor:"+message().sensor
            +" source:"+desc(message().source));
        DumpVelocity();

        // TODO: distinguish HOW we are getting bashed, i.e.
        //       if source==0 and velocity<(-15? 0?), then it
        //       is fall damage.
        local timeElapsed = (GetTime()-GetData("PressTime"));
        print("Time since last crouch press: "+timeElapsed);
        // TODO: tune press window
        // TODO: maybe allow slight window after hitting ground?
        if (0.0<=timeElapsed && timeElapsed<=0.2) {
            print("************ roll ************");
            // TODO: check for space to roll?
            // TODO: do a roll
        } else {
            // TODO: stochastic round?
            local damage = floor(message().intensity+0.5);
            Damage.Damage(self, 0, damage, (message().stimulus).tointeger());
        }
    }

    function OnDamage() {
        print("Damage kind:"+message().kind
            +" damage:"+message().damage
            +" culprit:"+message().culprit);
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

    function OnCreate() {
        if (! DEBUG_NOTELEPORT) {
            DarkGame.PlayerMode(ePlayerMode.kPM_Crouch);
            DarkGame.NoMove(true);
        }
        // TODO: unphysicalise the player (can we?) and DetailAttach them to
        //       the stunt double too.
        local spinner = Object.Create("fnord");
        Property.SetSimple(spinner, "ModelName", "swchwhe"); // has rotary joint
        if (DEBUG_VISIBLEPARTS)
            Property.SetSimple(spinner, "RenderType", 0); // Normal
        Object.Teleport(spinner, vector(), vector(), self);
        local link = Link.Create("DetailAttachement", spinner, self);
        LinkTools.LinkSetData(link, "rel rot", vector());
        Property.Add(spinner, "CfgTweqJoints");
        if (DEBUG_NODESTROY)
            Property.Set(spinner, "CfgTweqJoints", "Halt", TWEQ_HALT_STOP);
        else
            Property.Set(spinner, "CfgTweqJoints", "Halt", TWEQ_HALT_SLAY);
        Property.Set(spinner, "CfgTweqJoints", "AnimC", TWEQ_AC_SIM);
        Property.Set(spinner, "CfgTweqJoints", "MiscC", 0);
        Property.Set(spinner, "CfgTweqJoints", "CurveC" 0);
        Property.Set(spinner, "CfgTweqJoints", "Primary Joint", 1);
        Property.Set(spinner, "CfgTweqJoints", "Joint1AnimC", TWEQ_AC_SIM);
        Property.Set(spinner, "CfgTweqJoints", "Joint1CurveC", 0);
        Property.Set(spinner, "CfgTweqJoints", "    rate-low-high", vector(40.0,0,360));
        Property.Set(spinner, "StTweqJoints", "MiscS", 0);
        if (! DEBUG_NOROLL) {
            Property.Set(spinner, "StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
            Property.Set(spinner, "StTweqJoints", "Joint1AnimS", TWEQ_AS_ONOFF);
        }
        Property.Set(spinner, "Scripts", "Script 0", "RollSpinner");
        
        local anchor = Object.Create("fnord");
        Property.SetSimple(anchor, "ModelName", "waypt");
        if (DEBUG_VISIBLEPARTS)
            Property.SetSimple(anchor, "RenderType", 0); // Normal
        Object.Teleport(anchor, vector(), vector(), self);
        link = Link.Create("DetailAttachement", anchor, spinner);
        LinkTools.LinkSetData(link, "vhot/sub #", 1);
        LinkTools.LinkSetData(link, "Type", 4); // Subobject
        LinkTools.LinkSetData(link, "rel rot", vector(180,0,90));
        // TODO: offset for head location?
        // TODO: this x offset is a hack for the swchwhe, maybe make custom axisy thing?
        // TODO: this z offset is just me throwing numbers, its not quite the cam offset
        LinkTools.LinkSetData(link, "rel pos", vector(0.7,0,-1));

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
        local fac = Object.Facing("Player");
        // TODO: transfer remaining velocity to player.
        // TODO: make sure this goes in the right direction!!
        Physics.SetVelocity("Player", vector(-15,0,0));

        if (! DEBUG_NOTELEPORT) {
            // TODO: set position instead of teleport so as not to break awareness.
            Object.Teleport("Player", pos, fac, 0);
            // TODO: see if there is room to stand; stay crouched if not.
            DarkGame.PlayerMode(ePlayerMode.kPM_Stand);
            DarkGame.NoMove(false);
        }
        if (! DEBUG_NOATTACH)
            Camera.ForceCameraReturn();
        if (! DEBUG_NODESTROY)
            Object.Destroy(self);
    }
}

class RollSpinner extends SqRootScript
{
    function OnSlain() {
        print("RollSpinner: "+message().message);
        foreach (link in Link.GetAll("~ScriptParams")) {
            if (LinkTools.LinkGetData(link, "")=="StuntDouble") {
                print("Found stunt double: "+LinkDest(link));
                SendMessage(LinkDest(link), "RollComplete");
                return;
            }
        }
        print("Did not find stunt double ;_;");
    }

    function OnMessage() {
        print("RollSpinner: "+message().message);
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
