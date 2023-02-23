function UpdateGoals() {
    Quest.Set("goal_state_0",1);
    Quest.Set("goal_visible_1",1);
}

function ShowDecals(winning) {
    local bits = Quest.Get("BOOK_DECALS_HIDDEN0");
    bits = bits & 0xFFFFFFFC;
    if (winning) {
        bits = bits | 0x2;
    } else {
        bits = bits | 0x1;
    }
    Quest.Set("BOOK_DECALS_HIDDEN0", bits, eQuestDataType.kQuestDataCampaign);

}

function WinMission() {
    Quest.Set("MISSION_COMPLETE",1);
    DarkGame.EndMission();
}

class ChooseWisely extends SqRootScript {
    function OnFrobWorldEnd() {
        UpdateGoals();
        ShowDecals(true);
        WinMission();
    }
}

class ChoosePoorly extends SqRootScript {
    function OnFrobWorldEnd() {
        UpdateGoals();
        ShowDecals(false);
        WinMission();
    }
}
