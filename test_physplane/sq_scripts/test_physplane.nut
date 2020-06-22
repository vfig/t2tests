class MprintMessages extends SqRootScript {
    function OnBeginScript() {
        Physics.SubscribeMsg(self,
            ePhysScriptMsgType.kCollisionMsg
            | ePhysScriptMsgType.kContactMsg
            | ePhysScriptMsgType.kEnterExitMsg
            | ePhysScriptMsgType.kFellAsleepMsg
            | ePhysScriptMsgType.kWokeUpMsg
            | ePhysScriptMsgType.kMadePhysMsg
            | ePhysScriptMsgType.kMadeNonPhysMsg);
        SetOneShotTimer("foo", 2.0);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self,
            ePhysScriptMsgType.kCollisionMsg
            | ePhysScriptMsgType.kContactMsg
            | ePhysScriptMsgType.kEnterExitMsg
            | ePhysScriptMsgType.kFellAsleepMsg
            | ePhysScriptMsgType.kWokeUpMsg
            | ePhysScriptMsgType.kMadePhysMsg
            | ePhysScriptMsgType.kMadeNonPhysMsg);
    }

    function OnTimer() {
        print("---------------------");
        SetOneShotTimer("foo", 2.0);
    }

    function OnPhysEnter() {
        print(self.tostring() + ": " + message().message + " obj " + message().transObj + " submod: " + message().transSubmod);
    }

    function OnPhysExit() {
        print(self.tostring() + ": " + message().message + " obj " + message().transObj + " submod: " + message().transSubmod);
    }

    // function OnMessage() {
    //     print(self.tostring() + ": " + message().message + " from " + message().from);
    // }
}
