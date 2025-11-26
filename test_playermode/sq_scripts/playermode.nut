PLAYER_RADIUS <- (1.2)
PLAYER_HEIGHT <- (6.0)

PLAYER_HEAD <- (0)
PLAYER_FOOT <- (1)
PLAYER_BODY <- (2)
PLAYER_KNEE <- (3)
PLAYER_SHIN <- (4)

PLAYER_HEAD_POS <- ((PLAYER_HEIGHT / 2) - PLAYER_RADIUS)
PLAYER_FOOT_POS <- (-(PLAYER_HEIGHT / 2))
PLAYER_BODY_POS <- ((PLAYER_HEIGHT / 2) - (PLAYER_RADIUS * 3))
PLAYER_KNEE_POS <- (-(PLAYER_HEIGHT * (13.0 / 30.0)))
PLAYER_SHIN_POS <- (-(PLAYER_HEIGHT * (11.0 / 30.0)))


class TestPlayerMode extends SqRootScript
{
    function GetPlayerModeParam() {
        return ("PlayerMode" in userparams())? userparams().PlayerMode : "[None]";
    }

    function GetPlayerMode() {
        // NOTE: most of these honestly are pretty useless.
        //       Dead: does do the collapsing-to-the-ground thing with the player's
        //             head submodel, but even if you script a mode change back to Stand
        //             afterwards, that doesnt recover properly: you just go back to
        //             sliding around on the floor with your vision all sideways.
        //       Swim: doing this lets you move and jump around without making footsteps
        //             at all (possibly not even making contact with the ground?). you
        //             cant crouch, but you can mantle and you stay in swim mode after it.
        //             cant use weapons in this mode either.
        //       BodyCarry: well see the weapon discussion below.
        switch (GetPlayerModeParam()) {
            case "Stand": return ePlayerMode.kPM_Stand;
            case "Crouch": return ePlayerMode.kPM_Crouch;
            case "Swim": return ePlayerMode.kPM_Swim;
            case "Climb": return ePlayerMode.kPM_Climb;
            case "BodyCarry": return ePlayerMode.kPM_BodyCarry;
            case "Slide": return ePlayerMode.kPM_Slide;
            case "Jump": return ePlayerMode.kPM_Jump;
            case "Dead": return ePlayerMode.kPM_Dead;
            default: return ePlayerMode.kPM_Stand;
        }
    }

    function OnWorldSelect() {
        DarkUI.TextMessage(GetPlayerModeParam(), 0xFFFFFF, 2147483647);
    }

    function OnWorldDeSelect() {
        DarkUI.TextMessage("", 0xFFFFFF, 0);
    }

    function OnFrobWorldEnd() {
        local mode = GetPlayerMode();
        print("Change mode from "+DarkGame.GetPlayerMode()+" to "+mode);
        if (mode==ePlayerMode.kPM_Dead) {
            DoDeath();
        } else if (mode==ePlayerMode.kPM_Jump) {
            DarkGame.PlayerMode(mode);
            local player = Object.Named("Player");
            Property.Set(player, "PhysAttr", "Base Friction", 1.0);
            Physics.SetGravity(player, 0);
        } else {
            DarkGame.PlayerMode(mode);
        }
    }

    function OnTimer() {
        if (message().name=="Revive") {
            // // Attempt to force going back to full standing body posture -- but doesnt work
            // DarkGame.PlayerMode(ePlayerMode.kPM_Stand);
        }
    }

    function DoDeath() {
        local player = Object.Named("Player");

        // Setting mode to Dead does three things:
        // - disables control inputs.
        // - sets all player submodel offsets to zero.
        // - adds a rotational velocity to the PLAYER_HEAD submodel.
        //
        // Controls active prevents submodel rotation setting via the internal c api, but the damn
        // playermode doesnt use that, but directly gets the dynamics and calls its method.
        // DOESNT WORK: local controls = Property.Get(player, "PhysControl", "Controls Active");
        // DOESNT WORK: Property.Set(player, "PhysControl", "Controls Active", 0x10);

        // Surely death can't fuck with our physics model IF WE HAVE NO PHYSICS MODEL??
        // I mean, yes, but also IT ALL GOES VERY WEIRD AND WRONG. and crashes sometimes.
        // USELESS: Property.Set(player, "PhysType", "Type", 3); // None

        DarkGame.PlayerMode(ePlayerMode.kPM_Dead);
        // DOESNT WORK: Property.Set(player, "PhysControl", "Controls Active", controls);

        // If we change the player mode to something else, thatL
        // - enables control inputs again
        // - [only SHOCK2/DC] resets PLAYER_HEAD rotational velocity. [sadly i thought this happened
        // - [only SHOCK2/DC] resets the player's submodel arrangement.
        DarkGame.PlayerMode(ePlayerMode.kPM_Stand);

        // DOES NOTHING: DarkGame.RespawnPlayer();

        // At this point, we are a smol bean, with all our submodels at offset
        // zero; apart from that, we can move around normally.
        // But our head is sideways :(

        // the `lookcenter` bind command WILL ALSO reset head rotational velocity,
        // but being a bind-only command we cannot Debug.Command it.
        //
        // using player_cam_control 0 will allow head position to be reset AFTER
        // it settles. but anyway,  being a dromed-only command its not really suitable.
        // NOT GOOD ENOUGH: Debug.Command("player_cam_control 0");

        // So far, the only way i have found to reset all five player submodels
        // to normal, is by mantling (whether successful or not).
        // However, we can force the head and foot offsets back to normal values
        // via the PhysDims property, which lets us move around *almost* normally, until
        // we next attempt to mantle! (lacking proper shin/knee offsets probably only
        // affects wading in water? lacking proper body offset i think will affect
        // mantling, as well as affecting marginal climbing stuff: ladders maybe.)
        Property.Set(player, "PhysDims", "Offset 1", vector(0.0,0.0,PLAYER_HEAD_POS));
        Property.Set(player, "PhysDims", "Offset 2", vector(0.0,0.0,PLAYER_FOOT_POS));
    }
}


class TestWeapon extends SqRootScript
{
    function OnInvSelect() {
        // NOTE: using PlayerLimbs.Equip() is hardcoded to always apply the
        //       "carrying body" lowered head position. But for this mission
        //       we dont care; the player is basically disembodied the whole
        //       time they have this item equipped anyway.
        PlayerLimbs.Equip(self);
        // SO: just using DarkGame.PlayerMode() itself doesnt help with the
        //     PlayerLimbs api forcing you into BodyCarry mode, because it
        //     is doing that every frame.
        // BUT ALSO: if we try to override it every frame, that _sorta_ works,
        //     but we get completely headbob-free movement. its kinda gross.
        local timer = SetPeriodicTimer("Hack", 0.01);
        SetData("Timer", timer);
    }

    function OnInvDeSelect() {
        PlayerLimbs.UnEquip(self);
        KillTimer(GetData("Timer"));
    }

    function OnTimer() {
        if (message().name=="Hack") {
            DarkGame.PlayerMode(ePlayerMode.kPM_Stand);
        }
    }
}
