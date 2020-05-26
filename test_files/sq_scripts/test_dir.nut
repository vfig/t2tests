class TestDir extends SqRootScript
{
    function OnFrobWorldEnd() {
        print("calling dir...");
        local s = system("dir");
        print("result of dir: " + s);

    }
}

class TestFile extends SqRootScript
{
    function OnBeginScript() {
        print("TestFile ready!");
    }

    function OnFrobWorldEnd() {
        local fmpath = string();
        Version.GetCurrentFMPath(fmpath);
        local fmpath2 = string();
        Version.FMizeRelativePath("foo.bar", fmpath2);
        local fmpath3 = string();
        Version.FMizePath("foo.bar", fmpath3);
        print("FM path: " + fmpath);
        print("FMized relpath: " + fmpath2);
        print("FMized path: " + fmpath3);

        local path = fmpath.tostring();

        local filename = path + "\\testin.txt";
        print("TestFile reading " + filename);
        local f = file(filename, "rb");
        local value = f.readn('i');
        print("Read value: " + value);
        print("TestFile done!");
        f.close();

        local filename = path + "\\testout.txt";
        print("TestFile writing " + filename);
        local f = file(filename, "wb");
        local value = 1212630597;
        f.writen(value, 'i');
        print("TestFile done!");
        f.close();
    }
}

class TestSystem extends SqRootScript
{
    function OnBeginScript() {
        print("TestSystem ready!");
    }

    function OnTurnOn() {
        local fmpath = string();
        Version.GetCurrentFMPath(fmpath);
        local fmpath2 = string();
        Version.FMizeRelativePath("foo.bar", fmpath2);
        local fmpath3 = string();
        Version.FMizePath("foo.bar", fmpath3);
        print("FM path: " + fmpath);
        print("FMized relpath: " + fmpath2);
        print("FMized path: " + fmpath3);

        local path = fmpath.tostring();
        system("start " + path);

        print("TestSystem done!");
    }
}
