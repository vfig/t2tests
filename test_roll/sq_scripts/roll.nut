// TODO:
//    - all the TODOs below.
//    - could maybe have a sprint button?? with stamina ofc to prevent too much
//      abuse; would it be a hold or a toggle?
//        - cant detect key _held_ properly (just get repeat pings)
//            - _could_ have script that adds metaprop to player if not present,
//              or pings player to postpone removal of metaprop if present; but
//              the delay and repeat rate is likely from the user's settings in the os??
//    - see bug note in bnd.ini (BUG? commands after first dont show their string in the ui)

PRJ_FLG_ZEROVEL <-  (1 << 0);  // ignore launcher velocity
PRJ_FLG_PUSHOUT <-  (1 << 1);  // push away from launcher
PRJ_FLG_FROMPOS <-  (1 << 2);  // don't init position (only makes sense for concretes)
PRJ_FLG_GRAVITY <-  (1 << 3);  // object has gravity if default physics
PRJ_FLG_BOWHACK <-  (1 << 8);  // do all bow hackery
PRJ_FLG_TELLAI <-   (1 << 9);  // tell AIs about this object
PRJ_FLG_NOPHYS <-   (1 <<10);  // create the object without adding physics
PRJ_FLG_MASSIVE <-  (1 <<11);  // slow down the velocity based on projectile mass & launcher mass
PRJ_FLG_NO_FIRER <- (1<<12);   // don't create firer link

RADIANS_TO_DEGREES <- 180.0/3.1416;

function DegreesToUintHex(deg) {
    while (deg<0.0) deg += 360.0;
    while (deg>360.0) deg -= 360.0;
    return (deg*65536.0/360.0).tointeger();
}

function UintHexToDegrees(uinthex) {
    return (uinthex*360.0/65536.0);
}

function TeleportObj(obj, pos, fac=null) {
    // Teleport an object without snapping awareness links. Also breaks physics
    // contacts so the old problem of teleporting when up against an OBB no
    // longer prevents movement post-teleport.

    Property.Set(obj, "Position", "Location", pos);
    if (fac!=null) {
        Property.Set(obj, "Position", "Heading", DegreesToUintHex(fac.z));
        Property.Set(obj, "Position", "Pitch", DegreesToUintHex(fac.y));
        Property.Set(obj, "Position", "Bank", DegreesToUintHex(fac.x));
    }
    if (Physics.HasPhysics(obj)) {
        Property.Set(obj, "PhysState", "Location", pos);
        if (fac!=null) {
            Property.Set(obj, "PhysState", "Facing", fac);
        }
        // Physics.SetVelocity() breaks all contacts, even if the velocity
        // doesn't actually change!
        local vel = vector();
        Physics.GetVelocity(obj, vel);
        Physics.SetVelocity(obj, vel);
    }
}

class CmdRoll extends SqRootScript
{
    function OnPing() {
        SendMessage("Player", "CmdRoll", message().data, message().data2, message().data3)
    }
}

class Roll extends SqRootScript
{
    static DEBUG_LOG_COLLISIONS = false;
    static DEBUG_LOG_CONTACTS = false;
    static DEBUG_LOG_GROUNDED = false;
    static DEBUG_LOG_VELOCITY = false;
    static DEBUG_LOG_PHYSCAST = false;
    static DEBUG_PHYSCAST_STAY = false;

    static ROLL_VELOCITY_BOOST = 20.0;          // Extra speed from the roll.
    static ROLL_MIDAIR_VELOCITY_CUTOFF = -15.0; // Can't midair roll when falling faster than this.
    static ROLL_PRELANDING_WINDOW = 0.5;        // Start of window for pressing roll pre-landing.
    static ROLL_DAMAGE_REDUCTION = 6.0;         // How much a roll subtracts from incoming fall damage.
    static ROLL_VELOCITY_TRANSFER = 0.6;        // How much fall speed is transferred to a landing roll.
    static ROLL_MINIMUM_FORWARD_SPACE = 6.0;    // Can't roll forward with less space than this.
    static ROLL_CAMERA_OFFSETZ = 1.25;

    m_footContacts = null; // Foot tracks terrain and object contacts.
    m_shinContacts = null; // Shin tracks only object contacts (for sphere hats mostly).

    // Keep track of if a landing roll was requested.
    m_rollOnLanding = false;
    m_rollPressTime = 0.0;
    // Keep track of who bashed us for assigning damage blame in PhysCollision.
    // The PhysCollision message should always come in on the same frame, so
    // no need to preserve this over save/load.
    m_bashDeferred = false;
    m_bashTime = 0.0;
    m_bashIntensity = 0.0;

    constructor() {
        m_footContacts = {};
        m_footContacts["terrain"] <- 0;
        m_shinContacts = {};
    }

    function OnBeginScript() {
        if (Object.InheritsFrom(self, "Avatar")
        || self==Object.Named("Player")) {
            ActReact.SubscribeToStimulus(self, "BashStim");
            Physics.SubscribeMsg(self,
                 ePhysScriptMsgType.kCollisionMsg
                |ePhysScriptMsgType.kContactMsg);

            // Are we currently in a roll.
            if (! IsDataSet("IsRolling")) SetData("IsRolling", FALSE);

            if (DEBUG_LOG_GROUNDED) SetOneShotTimer("DumpGrounded", 0.1);
            if (DEBUG_LOG_VELOCITY) SetOneShotTimer("DumpVelocity", 0.1);
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

    function OnSlain() {
        // BUG: if you die during the roll (e.g. from radial stim),
        //      you are still... in the wrong place? investigate.
    }

    // TODO: remove
    function DumpVelocity() {
        local vel = vector();
        Physics.GetVelocity(self, vel);
        print("  Z vel:"+vel.z);
    }

    function OnCmdRoll() {
        // TODO: check if controls are locked out, e.g. from remote camera or NoMove() script api?
        // TODO: what if you are holding a junk item?
        // TODO: what if you are holding a weapon?
        // TODO: what if you are carrying a body?

        switch (DarkGame.GetPlayerMode()) {
        // Do a roll if grounded in these modes:
        case ePlayerMode.kPM_Stand:
        case ePlayerMode.kPM_Crouch:
        case ePlayerMode.kPM_Jump:
            // NOTE: After mantling a Sphere Hat object, you often remain in
            //       Jump mode, which is (at least partly) why you cant crouch
            //       until you move enough to step and go back to Stand mode.
            HandleCmdRoll();
            break;

        // Do nothing for other modes:
        case ePlayerMode.kPM_BodyCarry: // TODO: allow roll in BodyCarry and force body drop?
        case ePlayerMode.kPM_Swim:
        case ePlayerMode.kPM_Climb:
        case ePlayerMode.kPM_Slide:
        case ePlayerMode.kPM_Dead:
            break;
        }
    }

    function HackPhysRaycast(fromPos, direction, maxDistance, outHitPos=null, recycleObjects=false, destroyObjects=true) {
        // Do a raycast against terrain, OBBs, sphere hats, and spheres,
        // starting at `fromPos`, and going at least `maxDistance` units in
        // the given world-space direction. Return the distance to the first
        // hit (or the distance travelled, if no hit).

        // If you need to do multiple raycasts in a row, set recycleObjects=true
        // and (for all but the last one) destroyObjects=false, to reuse the
        // launcher and projectile to avoid object spam.

        // HACK ALERT!
        //
        // Use Physics.LaunchProjectile() to force a PhysRaycast so we can
        // detect OBBs and Sphere/Sphere Hat objects.
        //
        // If both launcher and projectile have physics, _and_ you use the
        // PRJ_FLG_PUSHOUT flag, _and_ the projectile physics is zero radius:
        // then launchProjectile() does a PhysRaycast out to "pushout distance",
        // to determine where to put the projectile. If the raycast hits, the
        // projectile is placed 95% along the line.
        //
        // Pushout distance is the sum of the bounding radiuses of the launcher
        // and projectile _models_ -- not their physics radiuses. But if an
        // object does not have a model, then a default radius is used for it,
        // of 2.0*max(scale.xyz)/sqrt(3). So we set the launcher scale to
        // maxDistance divided by that default radius, and the projectile scale
        // to zero, so that pushout distance ~= maxDistance.
        //
        // If you use the PRJ_FLG_FROMPOS flag with a concrete projectile, the
        // starting position _and_ facing of that projectile is used for the
        // launch, so the launcher facing is irrelevant.
        //
        // Finally, the PRJ_FLG_ZEROVEL and PRJ_FLG_NOPHYS flags are used to
        // ensure the projectile velocity will be zero, and the PRJ_FLG_NO_FIRER
        // flag is used because we don't care about having a Firer link.
        //

        if (DEBUG_PHYSCAST_STAY) {
            recycleObjects = false;
            destroyObjects = false;
        }

        local launcher = (recycleObjects? Object.Named("HackPhysLauncher") : 0);
        local projectile = (recycleObjects? Object.Named("HackPhysProjectile") : 0);

        if (DEBUG_LOG_PHYSCAST) {
            if (launcher!=0) print("Recycled launcher:"+launcher);
            if (projectile!=0) print("Recycled projectile:"+projectile);
        }

        if (launcher==0) {
            launcher = Object.BeginCreate("object");
            try {
                Object.SetName(launcher, "HackPhysLauncher");
                Property.Set(launcher, "PhysType", "Type", 1); // Sphere
                Property.Set(launcher, "PhysType", "# Submodels", 1);
                Property.Set(launcher, "PhysDims", "Radius 1", 0.0);
                Property.Set(launcher, "PhysDims", "Offset 1", 0.0);
                Property.Set(launcher, "PhysAttr", "Gravity %", 0.0);
                Property.Set(launcher, "PhysAttr", "Mass", 0.0);
                Property.SetSimple(launcher, "CollisionType", 0x0); // No collision.
                Property.SetSimple(launcher, "RenderType", 1); // Not rendered.
            } catch(e) {}
            Object.EndCreate(launcher);
            if (DEBUG_LOG_PHYSCAST) print("Created launcher:"+launcher);
        }

        if (projectile==0) {
            projectile = Object.BeginCreate("object");
            try {
                Object.SetName(projectile, "HackPhysProjectile");
                Property.Set(projectile, "PhysType", "Type", 1); // Sphere
                Property.Set(projectile, "PhysType", "# Submodels", 1);
                Property.Set(projectile, "PhysDims", "Radius 1", 0.0);
                Property.Set(projectile, "PhysDims", "Offset 1", 0.0);
                Property.Set(projectile, "PhysAttr", "Gravity %", 0.0);
                Property.Set(projectile, "PhysAttr", "Mass", 0.0);
                Property.Set(projectile, "PhysAttr", "Gravity %", 0.0);
                Property.Set(projectile, "PhysAttr", "Mass", 0.0);
                Property.SetSimple(projectile, "CollisionType", 0x0); // No collision.
                Property.SetSimple(launcher, "RenderType", 1); // Not rendered.
            } catch(e) {}
            Object.EndCreate(projectile);
            if (DEBUG_LOG_PHYSCAST) print("Created projectile:"+projectile);
        }

        // Calculate projectile facing:
        local facing = vector();
        direction = direction.GetNormalized();
        facing.y = -asin(direction.z)*RADIANS_TO_DEGREES;
        direction.z = 0.0;
        direction.Normalize();
        facing.z = atan2(direction.y, direction.x)*RADIANS_TO_DEGREES;

        // Set up for launch:
        Object.Teleport(launcher, fromPos, vector(), 0);
        Property.SetSimple(launcher, "ModelName", "");
        Property.SetSimple(launcher, "Scale", vector(1,1,1)*(maxDistance*0.5*sqrt(3)));
        Object.Teleport(projectile, fromPos, facing, 0);
        Property.SetSimple(projectile, "ModelName", "");
        Property.SetSimple(projectile, "Scale", vector());

        local result = Physics.LaunchProjectile(launcher, projectile, 0.0,
            PRJ_FLG_ZEROVEL|PRJ_FLG_PUSHOUT|PRJ_FLG_FROMPOS|PRJ_FLG_NO_FIRER|PRJ_FLG_NOPHYS,
            vector());

        if (result==0) {
            // The projectile ended up in an invalid position.
            // launchProjectile() will disable physics on the projectile in this
            // case, but because we gave it a concrete, it will not destroy it.
            // So we can still call Object.Position(), and don't actually care
            // about this warning.
            print("WARNING: HackPhysCast projectile ended in an invalid position!");
        }

        local toPos = Object.Position(projectile);
        local dist = (toPos-fromPos).Length();
        // launchProjectile pushes out to 95% of the hit distance, so undo that:
        dist = dist/0.95;

        if (DEBUG_PHYSCAST_STAY) {
            Object.SetName(launcher, "");
            Property.SetSimple(launcher, "ModelName", "unitbox");
            Property.SetSimple(launcher, "Scale", vector(1.0,1.0,1.0));
            Property.SetSimple(launcher, "RenderType", 2); // Unlit.
            Object.SetName(projectile, "");
            Property.SetSimple(projectile, "ModelName", "waypt");
            Property.SetSimple(projectile, "Scale", vector(0.25,0.25,0.25));
            Property.SetSimple(projectile, "RenderType", 2); // Unlit.
        } else {
            if (destroyObjects) {
                if (DEBUG_LOG_PHYSCAST) {
                    print("Destroying launcher:"+launcher);
                    print("Destroying projectile:"+projectile);
                }
                Object.Destroy(launcher);
                Object.Destroy(projectile);
            }
        }

        if (outHitPos!=null && (typeof outHitPos)=="vector") {
            outHitPos.x = toPos.x;
            outHitPos.y = toPos.y;
            outHitPos.z = toPos.z;
        }

        return dist;
    }


    function HandleCmdRoll() {
        if (GetData("IsRolling")) return;

        print("---- roll pressed ----");

        local isGrounded = IsGrounded();
        // Separate XY and Z velocity components.
        local velxy = vector();
        Physics.GetVelocity(self, velxy);
        local velz = velxy.z;
        velxy.z = 0.0;

        if (isGrounded || velz>=ROLL_MIDAIR_VELOCITY_CUTOFF) {
            // Grounded or not falling fast: do a roll now.

            // Get XY forward vector.
            local forward = Object.ObjectToWorld(self, vector(1,0,0))-Object.Position(self);
            forward.z = 0.0;
            forward.Normalize();

            // Boost velocity so we can roll from standing, or roll much
            // farther while running.
            print("Roll: velxy mag:"+velxy.Length());
            local boost = ROLL_VELOCITY_BOOST;
            if (! isGrounded) {
                // Reduce boost if rolling in midair (no ground to push off)
                boost *= 0.5;
            }
            velxy += (forward*boost)
            print("Roll: boost mag:"+velxy.Length());

            local fromFootLevel = isGrounded;
            DoRoll(velxy, fromFootLevel);
        } else {
            // If we land imminently, we will do a roll then.
            m_rollOnLanding = true;
            m_rollPressTime = GetTime();
            DumpVelocity();
        }
    }

    function DoRoll(velocity, fromFootLevel) {
        if (GetData("IsRolling")) return false;
        SetData("IsRolling", TRUE);

        // Doing a roll is too dangerous for the player, so we have a stunt
        // double do it. (We can't actually manage the player's physics nor
        // camera adequately, hence this fakery.)

        // If we start the stunt double exactly at our origin, it hits belly-
        // high objects that we _could_ roll under if we are too close to them
        // when starting the roll. So we start the stunt double from a point
        // relative to our foot instead (so its stance-independent). We add
        // a tiny bit of extra z clearance in case the foot is just under
        // something.
        //
        // But if we are in midair, we want to position the stunt double
        // relative to our head/camera so that we can dive roll onto tables and
        // other lowish surfaces. The 'fromFootLevel' parameter controls this.
        // We also throw in a fudge amount here so you can still roll mid-jump
        // when your head is right up against the ceiling (the fudge amount is
        // small enough to not clip into the ground in very low situations).

        local arch = Object.Named("StuntDouble");
        local radius = Property.Get(arch, "PhysDims", "Radius 1");
        local relpos = vector();
        local relfac = vector();
        local spawnpos;
        if (fromFootLevel) {
            Object.CalcRelTransform(self, self, relpos, relfac,
                4 /* RelSubPhysModel */, 1 /* PLAYER_FOOT */);
            local footpos = Object.ObjectToWorld(self, -relpos);
            spawnpos = footpos+vector(0,0,radius+0.05);
        } else {
            spawnpos = Camera.GetPosition()-vector(0,0,Roll.ROLL_CAMERA_OFFSETZ+0.25);
        }

        // Do raycasts forward/left/right/back see if there is enough room for
        // the stunt double to fit.
        local raycastLength = ROLL_MINIMUM_FORWARD_SPACE+2.0;
        local vpos = vector();
        local vneg = vector();

        // TODO: raycast 'local' direction MUST BE IN VELOCITY direction, not
        //       in FACING direction. so these are wrong [at least when we allow non-forward rolls]!
        local worldXDir = (Object.ObjectToWorld(self, vector(1,0,0))-Object.Position(self));
        local worldYDir = (Object.ObjectToWorld(self, vector(0,1,0))-Object.Position(self));

        // Check if physcasts report enough room.
        vpos.x = HackPhysRaycast(spawnpos, worldXDir, raycastLength, null, true, false);
        vneg.x = HackPhysRaycast(spawnpos, -worldXDir, raycastLength, null, true, false);
        vpos.y = HackPhysRaycast(spawnpos, worldYDir, raycastLength, null, true, false);
        vneg.y = HackPhysRaycast(spawnpos, -worldYDir, raycastLength, null, true, true);

        if (DEBUG_LOG_PHYSCAST) {
            print(message().message
                +" time:"+GetTime()
                +" -------------------------------------------------------------");
            print("Available space:"
                +" x:"+vneg.x+","+vpos.x
                +" y:"+vneg.y+","+vpos.y);
        }

        local radius = Property.Get(arch, "PhysDims", "Radius 1");
        local minForward = ROLL_MINIMUM_FORWARD_SPACE;
        if (minForward<radius) minForward = radius;

        if (vneg.x<radius || vpos.x<minForward
        || vneg.y<radius || vpos.y<radius) {
            // Not enough room.
            local adjusted = false;
            if (vpos.x>=minForward) {
                // If its only behind/left/right of us that there's not enough
                // room, try nudging the spawn pos instead of aborting.
                if (vneg.x<radius && (vpos.x+vneg.x)>2*radius) {
                    print("Roll: Adjusting spawn pos in +X");
                    spawnpos += worldXDir*vneg.x;
                    adjusted = true;
                }
                if (vneg.y<radius && (vpos.y+vneg.y)>2*radius) {
                    print("Roll: Adjusting spawn pos in +Y");
                    spawnpos += worldYDir*vneg.y;
                    adjusted = true;
                }
                if (vpos.y<radius && (vpos.y+vneg.y)>2*radius) {
                    print("Roll: Adjusting spawn pos in -Y");
                    spawnpos -= worldYDir*vpos.y;
                    adjusted = true;
                }
            }
            if (! adjusted) {
                // Nope, not enough room anywhere.
                print("Roll: Physcasts report not enough room for StuntDouble; aborting roll.");
                SetData("IsRolling", FALSE);
                Sound.PlaySchema(0, "gardrop");
                return false;
            }
        }

        // TODO: also support sideways/diagonal rolls if the player is strafing!
        //       (which means the player facing we restore to will not always
        //       be the same direction as the roll velocity).
        local spawnfac = Object.Facing(self);
        
        local o = Object.BeginCreate(arch)
        try {
            Object.Teleport(o, spawnpos, spawnfac, 0);
        } catch(e) {}
        Object.EndCreate(o);
        // NOTE: Physics.ValidPos() does not check against objects, so will allow
        //       rolling through doors. We have the whole physcast rigmarole above
        //       to manage that. We still double-check ValidPos() here so as to
        //       guarantee not rolling through terrain.
        if (! Physics.ValidPos(o)) {
            print("Roll: Physics reports invalid position for StuntDouble; aborting roll.");
            SetData("IsRolling", FALSE);
            Sound.PlaySchema(0, "gardrop");
            Object.Destroy(o);
        }

        // Start rolling!
        Physics.ControlCurrentRotation(o);
        Physics.SetVelocity(o, velocity);
        print("ROLL BEGIN. pos:"+spawnpos+" velocity:"+velocity);
        SendMessage(o, "RollBegin");

        return true;
    }

    function OnRollComplete() {
        SetData("IsRolling", FALSE);

        local remainingVel = message().data;
        print("ROLL COMPLETE. remainingVel:"+remainingVel);
        // Transfer remaining velocity to player.
        Physics.SetVelocity("Player", remainingVel);

    }

    function OnTimer() {
        switch (message().name) {
        case "DumpGrounded":
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
            break;
        case "DumpVelocity":
            DumpVelocity();
            SetOneShotTimer("DumpVelocity", 0.017);
            break;
        }
    }

    function OnBashStimStimulus() {

        // TODO: check downward and upward squishes to see if they are ambiguous
        //       (z velocity might help disambiguate)
        print("BashStim"
            +" time:"+GetTime()
            +" intensity:"+message().intensity
            +" sensor:"+message().sensor
            +" source:"+message().source);
        print("BashStim.sensor from:"+desc(LinkSource(message().sensor))+" to:"+desc(LinkDest(message().sensor)));
        print("BashStim.source from:"+desc(LinkSource(message().source))+" to:"+desc(LinkDest(message().source)));

        DumpVelocity();

        if (message().source==0) {
            // Physics bash.

            // We can't tell yet whether the bash is from an object hitting us
            // or the ground hiting us. We save the crucial details so we can
            // decide whether to apply damage or not when the PhysCollision happens.
            m_bashDeferred = true;
            m_bashTime = GetTime();
            m_bashIntensity = message().intensity;
        } else {
            // Stim bash. Damage immediately, don't defer it to PhysCollision.
            m_bashDeferred = false;
            local s = sLink(message().source);
            local culprit = s.source;
            ApplyBashStimDamage(message().intensity, culprit);
        }
    }

    function OnPhysCollision() {
        if (Roll.DEBUG_LOG_COLLISIONS) {
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

        // Check if we are hitting something downward.
        local isLanding = (message().collNormal.z>0.0);

        // TODO: do we really need this?
        if (m_bashDeferred) {
            // Sanity check the elapsed time since the BashStim
            local elapsedTime = (GetTime()-m_bashTime);
            if (elapsedTime>0) {
                print("*****************************************************************");
                print("*****************************************************************");
                print("*****************************************************************");
                print("*****************************************************************");
                print("*****************************************************************");
                print("*****************************************************************");
                print("************* ERROR: Nonzero deferred bash time:"+elapsedTime+" *************");
            }
        }

        if (! isLanding) {
            // A deferred bash from not landing gets applied now.
            if (m_bashDeferred) {
                ApplyBashStimDamage(m_bashIntensity, 0);
                m_bashDeferred = false;
                m_bashIntensity = 0.0;
            }
            return;
        }

        // Check if the player wanted to roll, but pressed too early (or too late):
        if (m_rollOnLanding) {
            local elapsedTime = (GetTime()-m_rollPressTime);
            print("  Roll: Time since last roll press: "+elapsedTime);
            // TODO: tune press window
            // TODO: maybe allow slight window after hitting ground?
            // TODO: maybe have the window only for better speed transfer, and
            //       allow a roll request anytime during the speedy fall?
            if (elapsedTime<0.0 || elapsedTime>ROLL_PRELANDING_WINDOW) {
                m_rollOnLanding = false;
            }
        }

        if (! m_rollOnLanding) {
            // A deferred bash from landing without a roll gets applied now.
            if (m_bashDeferred) {
                ApplyBashStimDamage(m_bashIntensity, 0);
                m_bashDeferred = false;
                m_bashIntensity = 0.0;
            }
            return;
        }

        // We are landing, and a roll was requested. Let's do it!
        print("  ************ roll ************");
        m_rollOnLanding = false;

        // Do a roll!

        // Separate XY and Z velocity components.
        local velxy = vector();
        Physics.GetVelocity(self, velxy);
        local velz = velxy.z;
        velxy.z = 0.0;
        // Get XY forward vector.
        local forward = Object.ObjectToWorld(self, vector(1,0,0))-Object.Position(self);
        forward.z = 0.0;
        forward.Normalize();
        // Convert z velocity into roll velocity.
        print("Roll: velz:"+velz);
        print("Roll: velxy mag:"+velxy.Length());
        local boost = fabs(velz)*ROLL_VELOCITY_TRANSFER;
        velxy += (forward*boost)
        print("Roll: boost mag:"+velxy.Length());

        local didRoll = DoRoll(velxy, false);

        if (m_bashDeferred) {
            // Reduce incoming damage if we had room to roll.
            local intensity = m_bashIntensity;
            if (didRoll) {
                intensity -= ROLL_DAMAGE_REDUCTION;
                print("Roll reduced damage from:"+m_bashIntensity+" to:"+intensity);
            }
            ApplyBashStimDamage(intensity, 0);
            m_bashDeferred = false;
            m_bashIntensity = 0.0;
        }
    }

    function ApplyBashStimDamage(intensity, culprit) {
        // Stochastically round damage amount, same as in DMGREACT.CPP:damage_func()
        local damage = floor(intensity + (Data.RandInt(0,99)/100.0));
        if (damage>0) {
            local stim = Object.Named("BashStim");
            Damage.Damage(self, culprit, damage, stim.tointeger());
        }
    }

    function OnDamage() {
        print("Damage"
            +" time:"+GetTime()
            +" kind:"+message().kind
            +" damage:"+message().damage
            +" culprit:"+message().culprit);
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
        if (count<0) { count = 0; print("ERROR: contact count underflow for "+key); }
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
            // NOTE: Using NoMove() kills the ability to hold W through the roll,
            //       which sucks. But using Add/RemoveSpeedControl() does not
            //       interfere with the input handling! And since we set the
            //       player's velocity to zero anyway, the result is perfect.
            DrkInv.AddSpeedControl("RollGlue", 0.0, 1.0);
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

        // NOTE: We can't remove PhysType from the player, because when adding
        //       it again, its just a default 1 big sphere, not the correct 5
        //       submodels. And we can't use Property.CopyFrom to copy the whole
        //       shebang either, cause that only sets Radius/Offset correctly
        //       for the first 2 submodels. So we have to make do with simply
        //       disabling all object collision for the duration of the roll.
        Property.SetSimple("Player", "CollisionType", 0); // None
        if (! DEBUG_VISIBLEPARTS)
            Property.SetSimple("Player", "RenderAlpha", 0.0);

        local spinner = Object.BeginCreate("fnord");
        try {
            Property.SetSimple(spinner, "ModelName", "axisjoints"); // has rotary joint
            Object.Teleport(spinner, vector(), vector(), self);
            Property.Set(spinner, "Scripts", "Script 0", "RollSpinner");
        } catch(e) {}
        Object.EndCreate(spinner);
        if (DEBUG_VISIBLEPARTS)
            Property.SetSimple(spinner, "RenderType", 0); // Normal
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
        
        local anchor = Object.BeginCreate("fnord");
        try {
            Property.SetSimple(anchor, "ModelName", "waypt");
            Object.Teleport(anchor, vector(), vector(), self);
        } catch(e) {}
        Object.EndCreate(anchor);
        if (DEBUG_VISIBLEPARTS)
            Property.SetSimple(anchor, "RenderType", 0); // Normal
        link = Link.Create("DetailAttachement", anchor, spinner);
        LinkTools.LinkSetData(link, "vhot/sub #", 6);
        LinkTools.LinkSetData(link, "Type", 4); // Subobject
        LinkTools.LinkSetData(link, "rel pos", vector(0,0,Roll.ROLL_CAMERA_OFFSETZ));
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
        local player = Object.Named("Player");
        TeleportObj(player, Object.Position(self));
    }

    function OnRollComplete() {
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
            TeleportObj("Player", pos, fac);
            // TODO: see if there is room to stand; stay crouched if not.
            DarkGame.PlayerMode(ePlayerMode.kPM_Stand);
            DrkInv.RemoveSpeedControl("RollGlue");
        }
        if (! DEBUG_NOATTACH)
            Camera.ForceCameraReturn();

        local vel = vector();
        Physics.GetVelocity(self, vel);
        // TODO: save/load the CollisionType instead of hardcoding?
        Property.SetSimple("Player", "CollisionType", 0x1); // Bounce
        // TODO: interaction with RenderAlpha set and invisibility potion?
        if (! DEBUG_VISIBLEPARTS)
            Property.SetSimple("Player", "RenderAlpha", 1.0);
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
