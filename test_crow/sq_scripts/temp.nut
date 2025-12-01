
class DebugTestScriptOverride extends SqRootScript {
    function OnTurnOn() {
        print(Object.GetName(self)+" ("+self+"): "+message().message);
        local target = LinkDest(Link.GetOne("ControlDevice", self));
        print("target:"+target);
        if (target && ! Object.HasMetaProperty(target, "MFooBar")) {
            print("add meta");
            Object.AddMetaProperty(target, "MFooBar")
        }
    }

    function OnTurnOff() {
        print(Object.GetName(self)+" ("+self+"): "+message().message);
        local target = LinkDest(Link.GetOne("ControlDevice", self));
        print("target:"+target);
        if (target && Object.HasMetaProperty(target, "MFooBar")) {
            print("remove meta");
            Object.RemoveMetaProperty(target, "MFooBar")
        }
    }
}

class PrintMe extends SqRootScript {
    function OnMessage() {
        print(Object.GetName(self)+" ("+self+"): "+message().message);
    }
}
