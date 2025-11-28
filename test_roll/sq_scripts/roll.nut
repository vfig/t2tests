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
}
