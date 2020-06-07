class TestHotkey extends SqRootScript
{
    //cmd = "game_message You pressed K";
    cmd = "metagame";

    function OnSim() {
        if (message().starting) {
            // This doesn't seem to work! And putting these in dark.bnd _or_ user.bnd in the fm directory
            // doesn't seem to work either :(

            if (! DarkUI.IsCommandBound(cmd)) {
                // Although 'bind k "metagame"' and so on work fine from the in-editor and in-game console,
                // they _don't_ seem to work with Debug.Command. I'm not sure why! Could maybe attach a
                // debugger to the old Dromed (the one with debug symbols) to find out?
                //
                ////Debug.Command("bind k \"" + cmd + "\"");
                //Debug.Command("bind", " k \"metagame\"");

                // But maybe this horrible hack will work?
                local path = string();
                Version.FMizePath("setbind", path);
                //local escapedPath = escape(path.tostring());
                //DarkUI.TextMessage();
                //Debug.Command("run", escapedPath);
                Debug.Command("run foo");
            } else {
                DarkUI.TextMessage("Already bound!");
            }
          
            SetOneShotTimer("testbinding", 2.0);
        }
    }

    function OnTimer() {
        if (! DarkUI.IsCommandBound(cmd)) {
            // Anyway, although I thought I got a 'bind' command in a script to work once, this
            // doesn't actually seem to work after all. Although running the fm-path-relative
            // command script does work.
            local path = string();
            Version.FMizePath("setbind", path);
            // Note: probably doesn't handle spaces in the path:
            local escapedPath = escape(path.tostring());
            Debug.Command("run", escapedPath);
            SetOneShotTimer("testbinding", 2.0);
            return;
        }

        if (message().name == "testbinding") {
            if (DarkUI.IsCommandBound(cmd)) {
                local binding = DarkUI.DescribeKeyBinding(cmd);
                DarkUI.TextMessage("Press " + binding + " for a secret message");
            } else {
                DarkUI.TextMessage("No binding :(");
            }
            SetOneShotTimer("testbinding", 1.0);
        }
    }

    //script_test crashes the game, only works in dromed
    function OnTest() {
        DarkUI.TextMessage("Hey, you pressed J!!");
        // print a game string!
    }
}