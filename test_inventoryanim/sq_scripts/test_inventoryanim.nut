class InventoryAnimate extends SqRootScript
{
    function startTweqing() {
        ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeAll, eTweqDo.kTweqDoActivate);
    }
    function stopTweqing() {
        ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeAll, eTweqDo.kTweqDoHalt);
    }

    // Inventory

    function OnFrobInvBegin() {
        print("FrobInvBegin");
    }
    function OnFrobInvEnd() {
        print("FrobInvEnd");
    }


    function OnInvSelect() {
        print("InvSelect");
        startTweqing();
    }
    function OnInvDeSelect() {
        print("InvDeSelect");
        stopTweqing();
    }


    function OnInvFocus() {
        print("InvFocus");
    }
    function OnInvDeFocus() {
        print("InvDeFocus");
    }


    // World

    function OnFrobWorldBegin() {
        print("FrobWorldBegin");
    }
    function OnInvFrobWorldEnd() {
        print("InvFrobWorldEnd");
    }


    function OnWorldSelect() {
        print("WorldSelect");
        //startTweqing();
    }
    function OnWorldDeSelect() {
        print("WorldDeSelect");
        //stopTweqing();
    }


    function OnWorldFocus() {
        print("WorldFocus");
    }
    function OnWorldDeFocus() {
        print("WorldDeFocus");
    }

}
