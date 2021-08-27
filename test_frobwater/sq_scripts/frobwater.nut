class TellMeYouFrobMe extends SqRootScript
{
    function OnToolFrob() {
        DarkUI.TextMessage(message().message, 0, 500.0);
    }

    function OnFrobWorldEnd() {
        DarkUI.TextMessage(message().message, 0, 500.0);
    }

    function OnFrobToolEnd() {
        SendMessage(message().DstObjId, "ToolFrob");
    }

    function OnMessage() {
        print("" + message().from + " ==" + message().message + "==> " + message().to);
    }
}
