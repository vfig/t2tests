print("dumpnet.nut loaded");

class DumpNet extends SqRootScript {
    function OnBeginScript() {
        local name = Object.GetName(self);
        print("<DumpNet ready on "+self+" '"+Object.GetName(self)+"'>");
    }

    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("DumpNet", 1.0);
            SetAvatarModel();
        }
    }

    function OnTimer() {
        if (message().name=="DumpNet") {
            SetOneShotTimer("DumpNet", 1.0);

            local s = "Dumping...\n";
            s=s+DumpNetInfo();
            DarkUI.TextMessage(s, 254);
        }
    }

    function DumpNetInfo() {
        local s = "";
        local isNetworking = Networking.IsNetworking();
        s=s+"IsNetworking:"+isNetworking+"\n";
        if (! isNetworking) return s;

        local isMultiplayer = Networking.IsMultiplayer()
        s=s+"IsMultiplayer:"+isMultiplayer+"\n";
        if (! isMultiplayer) return s;

        s=s+"AmHost:"+Networking.AmHost()+"\n";
        s=s+"NumPlayers:"+Networking.NumPlayers()+"\n";
        s=s+"MyPlayerNum:"+Networking.MyPlayerNum()+"\n";

        local p = Networking.FirstPlayer();
        local i = 1;
        while (p!=0 && i<=4) {
            s=s+"Player "+i+" ObjID:"+p+"\n";
            ++i; p = Networking.NextPlayer();
        }

        for (local i=0; i<=4; ++i) {
            local o = Networking.PlayerNumToObj(i);
            if (o==0) {
                s=s+"  Player "+i+". Not a player."+"\n";
                continue;
            }
            s=s+"  Player "+i+". ObjID:"+o+" Name:"+Networking.GetPlayerName(o)+"\n";
        }
        s=s+"  Done."+"\n";
        return s;
    }

    function SetAvatarModel() {
        if (Networking.IsNetworking()
        && Networking.IsMultiplayer()
        && Networking.MyPlayerNum()==2) {
            print("Trying to set model name");
            local arch = Object.Named("MP Avatar");
            print("MP Avatar: "+arch);
            local inherits = (arch!=0 && Object.InheritsFrom(self, arch));
            print("Do I inherit it? "+inherits);
        }

        for (local i=0; i<=4; ++i) {
            local o = Networking.PlayerNumToObj(i);
            if (o==0) continue;
            local name = Networking.GetPlayerName(o);
            if (name==null) continue;
            if (name=="AAA") {
                Property.SetSimple(o,"ModelName","haunt01");
            } else if (name=="BBB") {
                Property.SetSimple(o,"ModelName","basso");
            }
        }
    }
}
