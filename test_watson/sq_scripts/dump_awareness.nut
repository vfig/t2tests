class DumpAwareness extends SqRootScript {
    m_duration = 5.0;

    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("DumpAwareness", m_duration);
        }
    }

    function OnTimer() {
        if (message().name=="DumpAwareness") {
            DumpAwareness();
            SetOneShotTimer("DumpAwareness", m_duration);
        }
    }

    function DumpAwareness() {
        if (Link.AnyExist("AIAwareness", self)) {
            print("Awareness at time "+GetTime()+":")
            foreach (link in Link.GetAll("AIAwareness", self)) {
                // flags: "Seen", "Heard", "CanRaycast", "HaveLOS", "Blind", "Deaf", "Highest", "FirstHand"
                local flags = LinkTools.LinkGetData(link, "Flags");
                // enums: "(0) None", "(1) Low", "(2) Moderate", "(3) High"
                local level = LinkTools.LinkGetData(link, "Level");
                // enums: "(0) None", "(1) Low", "(2) Moderate", "(3) High"
                local peakLevel = LinkTools.LinkGetData(link, "Peak Level");
                local levelEnterTime = LinkTools.LinkGetData(link, "Level enter time");
                local timeLastContact = LinkTools.LinkGetData(link, "Time last contact");
                local posLastContact = LinkTools.LinkGetData(link, "Pos last contact");
                // enums: "(0) None", "(1) Low", "(2) Moderate", "(3) High"
                local lastPulseLevel = LinkTools.LinkGetData(link, "Last pulse level");
                local visionCone = LinkTools.LinkGetData(link, "Vision cone");
                local timeLastUpdate = LinkTools.LinkGetData(link, "Time last update");
                local timeLastUpdateLOS = LinkTools.LinkGetData(link, "Time last update LOS");
                local lastTrueContact = LinkTools.LinkGetData(link, "Last true contact");
                local freshness = LinkTools.LinkGetData(link, "Freshness");
                print("  "+self+"->"+LinkDest(link)
                    +" f:"+flags
                    +" l:"+level+"/"+peakLevel
                    +" let:"+levelEnterTime
                    +" tlc:"+timeLastContact
                    +" tlu:"+timeLastUpdate
                    +" ltc:"+lastTrueContact
                    +" fr:"+freshness);
            }
        }
    }
}
