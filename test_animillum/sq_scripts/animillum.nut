/* Put this on an AnimLight object, to have its model's brightness updated to
   match the actual brightness of the light.

   The light's "Renderer: Self Illumination" and/or "Renderer: Extra Light"
   properties (whichever it has) will be updated whenever the light changes.
*/
class AnimIllum extends SqRootScript {
    function OnBeginScript() {
        Light.Subscribe(self);
    }

    function OnEndScript() {
        Light.Unsubscribe(self);
    }

    function OnLightChange() {
        // The LightChange message only gets sent when the light's timer
        // expires, and not on each frame that it changes. But for smooth light
        // modes, we need to update every frame! We can't use a FlickerTweq
        // for this, as AnimLight special-cases that to mean "flicker when
        // turned on"; so we use a helper object with a FlickerTweq.
        local mode = Light.GetMode(self);
        if (mode==ANIM_LIGHT_MODE_SMOOTH
        || mode==ANIM_LIGHT_MODE_SMOOTH_BRIGHTEN
        || mode==ANIM_LIGHT_MODE_SMOOTH_DIM) {
            // Smooth mode? Make sure we have a helper to help; and update
            // this frame (to override the SelfIllum 1.0/0.0 that AnimLight
            // will set when turned on/off).
            GetOrSpawnHelper();
            UpdateBrightness();
        } else {
            // All the other modes, we can just update right now.
            local brightness = message().data.tofloat();
            local maxBrightness = message().data3.tofloat();
            SetIllum(brightness/maxBrightness);
        }
    }

    function OnLightFrame() {
        UpdateBrightness();
    }

    function UpdateBrightness() {
        // If the light is off, do nothing.
        if (Light.GetMode(self)==ANIM_LIGHT_MODE_EXTINGUISH) return;
        // Sigh. The AnimLight property has an internal 'brightness'
        // variable that it updates, but it is not exposed to scripts!
        // So we have to recalculate it here instead:
        local msToBrighten = GetProperty("AnimLight", "millisecs to brighten");
        local msToDim = GetProperty("AnimLight", "millisecs to dim");
        local maxBrightness = GetProperty("AnimLight", "max brightness");
        local minBrightness = GetProperty("AnimLight", "min brightness");
        local isRising = GetProperty("AnimLight", "currently rising?");
        local countdown = GetProperty("AnimLight", "current countdown");
        local t;
        if (isRising) {
            t = 1.0-(countdown.tofloat() / msToBrighten.tofloat());
        } else {
            t = countdown.tofloat() / msToDim.tofloat();
        }
        local brightness = minBrightness+t*maxBrightness;
        SetIllum(brightness/maxBrightness);
    }

    function SetIllum(illum) {
        if (HasProperty("SelfIllum"))
            SetProperty("SelfIllum", illum);
        if (HasProperty("ExtraLight")) {
            SetProperty("ExtraLight", "Amount (-1..1)", illum);
            SetProperty("ExtraLight", "Additive?", false);
        }
    }

    function GetOrSpawnHelper() {
        foreach (link in Link.GetAll("~ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="AnimIllum") {
                return LinkDest(link);
            }
        }
        // Did not find the helper. Spawn it! It needs to occupy the same
        // visual space as the light object itself, so that its will be
        // onscreen at the same times as the light object is, so that its
        // flicker tweq will only fire as and when needed.
        local helper = Object.BeginCreate("Object");
        Object.Teleport(helper, vector(), vector(), self);
        Property.SetSimple(helper, "ModelName", GetProperty("ModelName"));
        if (HasProperty("Scale")) Property.SetSimple(helper, "Scale", GetProperty("Scale"));
        Property.SetSimple(helper, "RenderType", 2); // Unlit
        Property.SetSimple(helper, "RenderAlpha", 0); // Must be rendered, but not seen.
        Property.Set(helper, "Scripts", "Script 0", "AnimIllumHelper");
        Property.Set(helper, "CfgTweqBlink", "Halt", TWEQ_STATUS_QUO);
        Property.Set(helper, "CfgTweqBlink", "AnimC", TWEQ_AC_WRAP);
        Property.Set(helper, "CfgTweqBlink", "MiscC", TWEQ_MC_SCRIPTS);
        Property.Set(helper, "CfgTweqBlink", "Rate", 16); // ~60fps
        Property.Set(helper, "StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
        Object.EndCreate(helper);
        local link = Link.Create("ScriptParams", helper, self);
        LinkTools.LinkSetData(link, "", "AnimIllum");
        return helper;
    }
}

class AnimIllumHelper extends SqRootScript {
    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            Link.BroadcastOnAllLinksData(self, "LightFrame", "ScriptParams", "AnimIllum");
        }
    }
}
