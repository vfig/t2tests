
GUICursor <- 0;

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

function GetObjectDimensions(obj) {
    // Measure the size of the gizmo, with a physics gimmick.
    // In the business, we call this a gizzfizzmick!
    // This is goddamn stupid, but it does work!
    local hasPhysics = Property.Possessed(obj, "PhysType");
    if (hasPhysics && Property.Get(obj, "PhysType", "Type")==3) { // None
        print("WARNING: has physics property, with None type.");
        hasPhysics = false;
    }
    if (!hasPhysics) {
        // Add physics, just for a moment!
        Property.Set(obj, "PhysType", "Type", 0);
    }
    local size = vector();
    local type = Property.Get(obj, "PhysType", "Type");
    if (type==0) { // OBB
        local sz = Property.Get(obj, "PhysDims", "Size");
        size.x = sz.x;
        size.y = sz.y;
        size.z = sz.z;
    } else if (type==1||type==2) { // Sphere, Sphere Hat
        local rad = Property.Get(obj, "PhysDims", "Radius 1");
        // Use the diameter.
        size.x = 2.0*rad;
        size.y = 2.0*rad;
        size.z = 2.0*rad;
    } else { // None
        print("WARNING: has physics property, with None type.");
    }
    if (!hasPhysics) {
        // Remove physics again
        Property.Set(obj, "PhysType", "Type", 3);
    }
    return size;
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
        local player = Object.Named("Player");
        local cameraPos = Camera.CameraToWorld(vector());
        local cameraLook = Camera.CameraToWorld(vector(1,0,0))-cameraPos;

        const maxScreenDistance = 7.0;
        local activeScreen = 0;
        local activeScreenDistance = 999999.0;

        // For determining gizmo coordinates:
        local activeScreenPos = vector();
        local activeScreenRight = vector();
        local activeScreenUp = vector();
        local activeScreenScale = vector();

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
            local scale = vector(1.0,1.0,1.0);
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
                activeScreenPos = screenPos;
                activeScreenRight = screenRight;
                activeScreenUp = screenUp;
                activeScreenScale = scale;
                cursorX = x;
                cursorY = y;
                cursorWorldSpace.x = hitPosWorldSpace.x;
                cursorWorldSpace.y = hitPosWorldSpace.y;
                cursorWorldSpace.z = hitPosWorldSpace.z;
            }
        }

        // Do a raycast to see if anything else is occluding the active screen.
        local refRayHitObj = object();
        local rayHitPos = vector();
        if (Engine.ObjRaycast(cameraPos, cursorWorldSpace, rayHitPos, refRayHitObj, 0, 0x2, player, GUICursor)) {
            local rayHitObj = refRayHitObj.tointeger();
            if (rayHitObj!=0
            && rayHitObj!=activeScreen
            && ! Link.AnyExist("Owns", activeScreen, rayHitObj)) {
                // We hit something that is not this screen, nor belongs to it.
                // This means the screen is occluded.
                activeScreen = 0;
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
        if (GUICursor!=0) {
            if (activeScreen!=0) {
                Property.Set(GUICursor, "Position", "Location", cursorWorldSpace);
                Property.SetSimple(GUICursor, "RenderType", 0);
            } else {
                Property.SetSimple(GUICursor, "RenderType", 1);
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

            // TODO: support Bitmap Worldspace gizmos

            // look for active gizmos
            local activeGizmo = 0;
            foreach (link in Link.GetAll("Owns", screen)) {
                slink.LinkGet(link);
                local gizmo = slink.dest;

                // Get the gizmo position and size in gui space.
                // TODO: this call is the biggest hit in performance. Consider
                // caching gizmo dimensions.
                local gizmoSize = GetObjectDimensions(gizmo);
                if (Property.Possessed(gizmo, "Scale")) {
                    // The ObjectToWorld() call applies the scale (when all I
                    // really want is the orientation). So divide by object
                    // scale in advance.
                    local scale = Property.Get(gizmo, "Scale");
                    gizmoSize.x /= scale.x;
                    gizmoSize.y /= scale.y;
                    gizmoSize.z /= scale.z;
                }
                local gizmoPos = Object.Position(gizmo);
                local gizmoScreenRelPos = gizmoPos-activeScreenPos;
                local centerX = gizmoScreenRelPos.Dot(activeScreenRight)/activeScreenScale.y+0.5;
                local centerY = 1.0-(gizmoScreenRelPos.Dot(activeScreenUp)/activeScreenScale.z+0.5);
                local corner = Object.ObjectToWorld(gizmo, gizmoSize*0.5)-gizmoPos;
                local halfWidth = fabs(corner.Dot(activeScreenRight)/activeScreenScale.y);
                local halfHeight = fabs(corner.Dot(activeScreenUp)/activeScreenScale.z);

                // Check if the cursor is over this gizmo.
                local x0 = centerX-halfWidth;
                local y0 = centerY-halfHeight;
                local x1 = centerX+halfWidth;
                local y1 = centerY+halfHeight;
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
        GUICursor = object(message().data).tointeger();
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
