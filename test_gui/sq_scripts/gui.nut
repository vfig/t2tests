
GUICursor <- null;

function IntersectRayPlane(rayOrigin, rayDirection, planeOrigin, planeNormal, hitLocation) {
    local denom = planeNormal.Dot(rayDirection);
    if (fabs(denom) > 0.001) { // pretty coarse
        local t = (planeOrigin-rayOrigin).Dot(planeNormal)/denom;
        if (t>=0) {
            local hit = rayOrigin+rayDirection*t;
            hitLocation.x = hit.x;
            hitLocation.y = hit.y;
            hitLocation.z = hit.z;
            return true;
        }
    }
    return false;
}

class cGUIOverlay extends IDarkOverlayHandler {
    m_screens = null;

    function Init() {
        m_screens = [];
        m_screens.append( Object.Named("screen1") );
        m_screens.append( Object.Named("screen2") );
    }

    function Term() {
        foreach (i, o in m_screens)
            m_screens[i] = null;
        m_screens = null;
    }

    // IDarkOverlayHandler interface
    function DrawHUD() {
        local cameraPos = Camera.CameraToWorld(vector());
        local cameraLook = Camera.CameraToWorld(vector(1,0,0))-cameraPos;

        const maxScreenDistance = 7.0;
        local activeScreen = 0;
        local activeScreenDistance = 999999.0;
        local cursorX = -1.0, cursorY = -1.0;
        local cursorWorldSpace = vector();

        foreach (i, screen in m_screens) {
            // support either a screen with a Bitmap Worldspace shape,
            // or a screen with gui_unit as its shape.
            local bitmapWorldSpace = Property.Possessed(screen, "BitmapWorld");
            local modelName = Property.Get(screen, "ModelName");
            if (!bitmapWorldSpace && modelName!="gui_unit") {
                print("WARNING: screen with wrong model '"+modelName"' is ignored.");
                continue;
            }

            // get the plane of the screen
            local ref = bitmapWorldSpace? vector(0.0,0.0,1.0) : vector(1.0,0.0,0.0);
            local screenPos = Object.Position(screen);
            local screenNormal = Object.ObjectToWorld(screen, ref)-screenPos;
            if ((screenPos-cameraPos).Length()>maxScreenDistance)
                continue;

            // intersect the camera look with the screen plane
            local hitPosWorldSpace = vector();
            local hit = IntersectRayPlane(cameraPos, cameraLook, screenPos, screenNormal, hitPosWorldSpace);
            // ghetto cursor, in the plane of the screen
            // TODO: cursor handling needs to be global!
            if (!hit)
                continue;

            // get the cursor position in screen coordinates
            local hitPos = hitPosWorldSpace-screenPos;
            local hitDistance = (hitPos-cameraPos).Length();
            ref = bitmapWorldSpace? vector(0.0,1.0,0.0) : vector(0.0,0.0,1.0);
            local screenUp = Object.ObjectToWorld(screen, ref)-screenPos;
            screenUp.Normalize();
            ref = bitmapWorldSpace? vector(1.0,0.0,0.0) : vector(0.0,1.0,0.0);
            local screenRight = Object.ObjectToWorld(screen, ref)-screenPos;
            screenRight.Normalize();
            local scale = vector(1.0,1.0,1.0);;
            if (bitmapWorldSpace) {
                scale.y = Property.Get(screen, "BitmapWorld", "x size (feet)");
                scale.z = Property.Get(screen, "BitmapWorld", "y size (feet)");
            } else {
                if (Property.Possessed(screen, "Scale")) {
                    scale = Property.Get(screen, "Scale");
                }
            }
            local x = hitPos.Dot(screenRight)/scale.y+0.5;
            local y = 1.0-(hitPos.Dot(screenUp)/scale.z+0.5);

            // then "is the cursor on screen" is easy.
            local cursorOnScreen = (x>=0 && x<1.0 && y>=0 && y<1.0);

            if (cursorOnScreen && hitDistance<activeScreenDistance) {
                activeScreen = screen;
                cursorX = x;
                cursorY = y;
                cursorWorldSpace.x = hitPosWorldSpace.x;
                cursorWorldSpace.y = hitPosWorldSpace.y;
                cursorWorldSpace.z = hitPosWorldSpace.z;
            }
        }

        // Brighten the active screen only
        foreach (screen in m_screens) {
            if (screen==activeScreen) {
                Property.Set(screen, "ExtraLight", "Amount (-1..1)", 0.1);
                Property.Set(screen, "ExtraLight", "Additive?", true);
            } else {
                Property.Set(screen, "ExtraLight", "Amount (-1..1)", -0.2);
                Property.Set(screen, "ExtraLight", "Additive?", true);
            }
        }

        // I wanted to slow the mouse when it's on a screen, but the rot_fac
        // parameter to DrkInv.AddSpeedControl() is only taken into account
        // when looking **with the keyboard**. And who does that?

        // ghetto mouse cursor:
        if (GUICursor!=null) {
            if (activeScreen!=0) {
                Property.Set(GUICursor.tointeger(), "Position", "Location", cursorWorldSpace);
                Property.SetSimple(GUICursor.tointeger(), "RenderType", 0);
            } else {
                Property.SetSimple(GUICursor.tointeger(), "RenderType", 1);
            }
        }

        // handle gizmos
        local slink = sLink();
        const kFrobIgnore = 8;
        foreach (screen in m_screens) {
            // disable all gizmos in inactive screens
            if (screen!=activeScreen) {
                foreach (link in Link.GetAll("Owns", screen)) {
                    slink.LinkGet(link);
                    local gizmo = slink.dest;
                    local frob = Property.Get(gizmo, "FrobInfo", "World Action").tointeger();
                    if ((frob&kFrobIgnore)==0) {
                        Property.Set(gizmo, "FrobInfo", "World Action", frob|kFrobIgnore);
                    }
                }
                continue;
            }

            // look for active gizmos
            local activeGizmo = 0;
            foreach (link in Link.GetAll("Owns", screen)) {
                slink.LinkGet(link);
                // todo: get screen-space position and bounds of the gizmo!
                local gizmo = slink.dest;
                local w = 0.92/8.0;
                local h = 1.07/4.5;
                local x0 = 0.5-0.5*w;
                local y0 = 0.5-0.5*h;
                local x1 = 0.5+0.5*w;
                local y1 = 0.5+0.5*h;
                local cursorOver = (cursorX>=x0 && cursorX<x1 && cursorY>=y0 && cursorY<y1);
                if (cursorOver && activeGizmo==0) {
                    activeGizmo = gizmo;
                }

                // Enable frobbing for the active gizmo; disable it for the rest.
                local frob = Property.Get(gizmo, "FrobInfo", "World Action").tointeger();
                if (activeGizmo==gizmo && (frob&kFrobIgnore)==kFrobIgnore) {
                    frob = frob&~kFrobIgnore;
                    Property.Set(gizmo, "FrobInfo", "World Action", frob);
                } else if (activeGizmo!=gizmo && (frob&kFrobIgnore)==0) {
                    frob = frob|kFrobIgnore;
                    Property.Set(gizmo, "FrobInfo", "World Action", frob);
                }
            }
        }
    }
    // function DrawTOverlay() {}
    // function OnUIEnterMode() {}
}


GUIOverlay <- cGUIOverlay();


//
// Script that installs and uninstalls the overlay handler
// Add this script to one (dummy) object in the mission
//

class GUIController extends SqRootScript
{
    function destructor()
    {
        // to be on the safe side make really sure the handler is removed when this script is destroyed
        // (calling RemoveHandler if it's already been removed is no problem)
        DarkOverlay.RemoveHandler(GUIOverlay);
    }

    function OnBeginScript()
    {
        DarkOverlay.AddHandler(GUIOverlay);
        GUIOverlay.Init();
    }

    function OnEndScript()
    {
        DarkOverlay.RemoveHandler(GUIOverlay);
        GUIOverlay.Term();
    }

    function OnSetCursor() {
        GUICursor = object(message().data);
        print(message().message+": "+GUICursor);
    }
}


class GUICursor extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            local link = Link.GetOne("~ScriptParams", self);
            if (link && LinkTools.LinkGetData(link,"")=="GUICursor") {
                SendMessage(LinkDest(link), "SetCursor", self);
            }
        }
    }
}
