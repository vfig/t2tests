class JunkTool extends SqRootScript
{
    kModeJunk = 0;
    kModeTool = 1;

    function OnBeginScript() {
        // NOTE: changes to disable_modal_tool_frob being set/unset only
        //       take effect when game mode changes.
        Debug.Command("set disable_modal_tool_frob");
    }

    function OnSim() {
        if (message().starting) {
            SetMode(kModeJunk);
        }
    }

    function OnDarkGameModeChange() {
        if (message().resuming) {
            // Make sure everything is in the right state when we load a game.
            SetMode(kModeJunk);
        }
    }

    function OnIsJunkTool_() {
        Reply(1);
    }

    function IsJunkMode() {
        return (GetData("Mode")==kModeJunk);
    }

    function IsToolMode() {
        return (GetData("Mode")==kModeTool);
    }

    function SetMode(mode) {
        SetData("Mode", mode);
        SetProperty("InvType", (mode==kModeJunk? 0 : 1));
        if (mode==kModeJunk) {
            //Debug.Command("unset disable_modal_tool_frob");
        } else {
            //Debug.Command("set disable_modal_tool_frob 1");
        }
    }

    function OnBecomeJunk() {
        SetMode(kModeJunk);
    }

    function OnBecomeTool() {
        SetMode(kModeTool);
    }

    function OnFrobToolBegin() {
        local target = message().DstObjId;
        if (target!=0) {
            SendMessage(target, "TurnOn");
        }
    }

    function OnInvDeFocus() {
        PreventDeselect();
    }

    function OnInvDeSelect() {
        PreventDeselect();
    }

    function PreventDeselect() {
        // Prevent from being deselected in inventory.
        // NOTE: neither DarkUI.InvSelect(self) nor the inv_select command works
        //       to prevent the weapon from being deselected! So we post a
        //       message to force a reselection next frame.
        // BUG: neither the immediate-InvSelect() nor the next-frame InvSelect()
        //      is robust! we can, when in tool-cursor mode, scroll wheel to
        //      *try* to select the key (but it doesnt select); but then after
        //      that we can backspace to defocus the object anyway :(
        DarkUI.InvSelect(self);
        PostMessage(self, "ForceReselect");
    }

    function OnForceReselect() {
        DarkUI.InvSelect(self);
    }
}


class JunkToolTarget extends SqRootScript
{
    kModeIdle = 0;
    kModeActive = 1;
    kFocusScript = 0x10;

    function OnSim() {
        if (message().starting) {
            SetMode(kModeIdle);
        }
    }

    function OnDarkGameModeChange() {
        if (message().resuming) {
            // Make sure everything is in the right state when we load a game.
            SetMode(kModeIdle);
        }
    }

    function IsIdle() {
        return (GetData("Mode")==kModeIdle);
    }

    function IsActive() {
        return (GetData("Mode")==kModeActive);
    }

    function SetMode(mode) {
        SetData("Mode", mode);
        EnableFlickerTweq(mode==kModeIdle);
        EnableWorldFocus(mode==kModeActive);
    }

    function EnableFlickerTweq(enable) {
        local animS = GetProperty("StTweqBlink", "AnimS");
        if (enable) {
            animS = animS | TWEQ_AS_ONOFF;
        } else {
            animS = animS & ~TWEQ_AS_ONOFF;
        }
        SetProperty("StTweqBlink", "AnimS", animS);
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            if (IsIdle()
            && IsJunkToolHeld()
            && IsLookedAt()) {
                SetMode(kModeActive);
                ActivateJunkTool(true);
            }
        }
    }

    function IsWorldFocusEnabled() {
        return ((GetProperty("FrobInfo", "World Action")&kFocusScript)!=0);
    }

    function EnableWorldFocus(enable) {
        local worldFrob = GetProperty("FrobInfo", "World Action");
        if (enable) {
            worldFrob = worldFrob | kFocusScript;
        } else {
            worldFrob = worldFrob & ~kFocusScript;
        }
        SetProperty("FrobInfo", "World Action", worldFrob);
    }

    function IsLookedAt() {
        // Slightly expensive, because of the raycast.
        local player = Object.Named("Player");
        local rayFrom = Camera.CameraToWorld(vector());
        local rayTo = Camera.CameraToWorld(vector(10.0,0,0));
        local hitPos = vector();
        local hitObj = object();
        local hit = Engine.ObjRaycast(rayFrom, rayTo, hitPos, hitObj, 0, 0x3, player, 0);
        return (hit==2 && hitObj.tointeger()==self);
    }

    function IsJunkToolHeld() {
        local tool = DarkUI.InvItem();
        if (tool==0) {
            return false;
        } else {
            return (SendMessage(tool, "IsJunkTool?")==1);
        }
    }

    function ActivateJunkTool(activate) {
        local invItem = DarkUI.InvItem();
        if (invItem!=0) {
            SendMessage(invItem, activate? "BecomeTool" : "BecomeJunk");
        }
    }

    function OnWorldDeSelect() {
        if (IsJunkToolHeld()) {
            SetMode(kModeIdle);
            ActivateJunkTool(false);
        }
    }
}


// NOTE: this is just so we can have the gear do something when
//       frobbed with the junk item. not a part of the JunkTool stuff.
class ToggleTweqRotate extends SqRootScript
{
    function OnTurnOn() {
        local animS = GetProperty("StTweqRotate", "AnimS");
        animS = animS^1;
        SetProperty("StTweqRotate", "AnimS", animS);
    }
}
