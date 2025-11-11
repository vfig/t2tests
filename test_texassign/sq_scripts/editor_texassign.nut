ASCII <- " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x007f";

blob_slice <- function(blob, start, stop) {
    // Extremely inefficient, but this is run in dromed only, so its fine.
    local s = "";
    for (local i=start; i<stop; ++i) {
        local c = blob[i];
        if (c>=32 && c<128) s += ASCII.slice(c-32,c-31);
        else if (c==9) s += "\t";
        else if (c==10) s += "\n";
        /* else skip */;
    }
    return s;
}

class BlobReader {
    blob = null;
    pos = 0;
    line = "";
    done = true;

    constructor(in_blob) {
        blob = in_blob;
        restart();
    }

    function next() {
        _advance();
    }

    function restart() {
        pos = 0;
        line = "";
        done = false;
        _advance();
    }

    function _advance() {
        if (pos<blob.len()) {
            local i;
            for (i=pos; i<blob.len(); ++i) {
                if (blob[i]==10)
                    break;
            }
            line = blob_slice(blob, pos, i);
            pos = i+1;
        } else {
            line = "";
            done = true;
        }
    }
}

class EditorTexAssign extends SqRootScript {
    function read_file(filename) {
        local filepath_ref = string();
        Version.FMizeRelativePath(filename, filepath_ref);
        local f = file(filepath_ref.tostring(), "rb");
        local blob = f.readblob(f.len());
        f.close();
        return blob;
    }

    function OnBeginScript() {
        if (! IsEditor()) {
            Object.Destroy(self);
        }
    }

    function OnTest() {
        if (! IsEditor())
            return;

        local blob = read_file("tex_assign.txt");
        local line_no = 0;
        for (local r = BlobReader(blob); !r.done; r.next()) {
            local line = r.line;
            ++line_no;

            // TODO: not a line reader, but the parser should work
            //       with the raw data, honestly. i guess it can be
            //       line by line.

            // if (line.len()==0) continue;
            // if (line.slice(0,1)==";") continue;
            // if (line.slice(0,1)==";") continue;
            // if (==";"
            // print(line_no+": "+line);
            // print(r.line.slice([0]);
        }
    }
}

class EditorTexDump extends SqRootScript {
    function OnBeginScript() {
        if (! IsEditor()) {
            Object.Destroy(self);
        }
    }

    function OnTest() {
        if (! IsEditor())
            return;

        local tree = {};
        local queue = get_children(Object.Named("Texture"));

        
        print("\nTexture:")
        
        print("\nWoodTex:")
        get_children(Object.Named("MawTex"));
    }

    function get_children(arch) {
        local i = 0;
        local children = [];
        foreach (link in Link.GetAll("~MetaProp", arch)) {
            children.append(LinkDest(link));
        }
        return children;
    }
}
