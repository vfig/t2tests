
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
    }

    function Term() {
        foreach (i, o in m_screens)
            m_screens[i] = null;
        m_screens = null;
    }

    refX0 = int_ref();
    refY0 = int_ref();
    refX1 = int_ref();
    refY1 = int_ref();

    // IDarkOverlayHandler interface
    function DrawHUD() {
        local cameraPos = Camera.CameraToWorld(vector());
        local cameraLook = Camera.CameraToWorld(vector(1,0,0))-cameraPos;
        //print("cameraPos: "+cameraPos+"; look: "+cameraLook);
        local cursorX, cursorY, onScreen, underCursor;

        foreach (i, screen in m_screens) {
            // get the plane of the screen
            local screenPos = Object.Position(screen);
            local screenNormal = Object.ObjectToWorld(screen, vector(1.0,0.0,0.0))-screenPos;

            // intersect the camera look with the screen plane
            local hitPos = vector();
            local hit = IntersectRayPlane(cameraPos, cameraLook, screenPos, screenNormal, hitPos);
            if (!hit)
                continue;

            // ghetto cursor, in the plane of the screen
            if (GUICursor!=null) {
                Property.Set(GUICursor.tointeger(), "Position", "Location", hitPos);
            }

            // get the cursor position in screen coordinates
            hitPos = hitPos - screenPos;
            local screenUp = Object.ObjectToWorld(screen, vector(0.0,0.0,1.0))-screenPos; screenUp.Normalize();
            local screenRight = Object.ObjectToWorld(screen, vector(0.0,1.0,0.0))-screenPos; screenRight.Normalize();
            local scale = Property.Get(screen, "Scale");
            cursorX = hitPos.Dot(screenRight)/scale.y+0.5;
            cursorY = 1.0-(hitPos.Dot(screenUp)/scale.z+0.5);

            // then "is the cursor on screen" is easy.
            underCursor = (cursorX>=0 && cursorX<1.0 && cursorY>=0 && cursorY<1.0);

            if (underCursor) {
                Property.Set(screen, "ExtraLight", "Amount (-1..1)", 1.0);
                Property.Set(screen, "ExtraLight", "Additive?", false);
            } else {
                Property.Set(screen, "ExtraLight", "Amount (-1..1)", -0.25);
                Property.Set(screen, "ExtraLight", "Additive?", true);
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
