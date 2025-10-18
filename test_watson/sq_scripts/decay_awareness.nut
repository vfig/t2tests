Object_Description <- function(obj)
{
    local name;
    if (obj == 0) {
        name = "[nothing]";
    } else {
        name = Object.GetName(obj);
        if (name == "") {
            // Look up the archetype's name instead.
            local archetype_name = Object.GetName(Object.Archetype(obj));
            if (archetype_name == "") {
                name = "[unknown]";
            } else {
                local first = archetype_name.slice(0, 1).toupper();
                if (first == "A" || first == "E" || first == "I" || first == "O" || first == "U") {
                    name = "an " + archetype_name;
                } else {
                    name = "a " + archetype_name;
                }
            }
        }
    }
    return (name + " (" + obj + ")");
}

AI_AlertLevel <- function(ai)
{
    return Property.Get(self, "AI_Alertness", "Level");
}

AI_HostileTeam <- function(team1, team2)
{
    return ((team1 != eAITeam.kAIT_Neutral)
        && (team2 != eAITeam.kAIT_Neutral)
        && (team1 != team2));
}

AI_Mode <- function(ai)
{
    return Property.Get(ai, "AI_Mode", "");
}

AI_Team <- function(ai)
{
    return Property.Get(ai, "AI_Team", "");
}

class DecayAwareness extends SqRootScript
{
    // Makes AIs give up investigating and return to normal alert levels
    // much sooner than normal. Default is investigation ends 30s after contact,
    // and alertness ends 120s after contact. That's way too long!

    // Minimum time (in seconds) to investigate.
    kInvestigateMinAge = 10.0;

    // Maximum time (in seconds) to persist level 2 and 3 awareness, respectively.
    kAwarenessMaxAge2 = 5.0;
    kAwarenessMaxAge3 = 10.0;

    // Spam monolog with useful info?
    kDebugEnabled = false;

    function Log(message) {
        if (kDebugEnabled) {
            print("[DA: "+Object_Description(self)+"] "+message);
        }
    }

    function OnBeginScript()
    {
        Log("is lazy.");

        // Set up a Flicker tweq every second.
        Property.Set(self, "CfgTweqBlink", "Halt", 3); // Continue
        Property.Set(self, "CfgTweqBlink", "AnimC", 0x3); // NoLimit|Sim
        Property.Set(self, "CfgTweqBlink", "MiscC", 0x2); // Scripts
        Property.Set(self, "CfgTweqBlink", "CurveC", 0x0);
        Property.Set(self, "CfgTweqBlink", "Rate", 1000);
        // But don't start it yet.
        Property.Set(self, "StTweqBlink", "AnimS", 0);
    }

    function OnEndScript()
    {
        Log("is no longer lazy.");
        Property.Set(self, "StTweqBlink", "AnimS", 0);
    }

    function OnTweqComplete()
    {
        // Don't try to stop looking if we're busy attacking!
        if (! Link.AnyExist("AIAttack", self)) {
            Log("is at alert " + AI_AlertLevel(self) + " and still lazy.");
            ExpireAwareness();
        } else {
            Log("is busy attacking something.");
        }
    }

    function OnAlertness()
    {
        if (message().level >= 2) {
            // Start the tweq.
            Log("is alert, but lazy.");
            Property.Set(self, "StTweqBlink", "AnimS", 1);
        } else if (message().level < 2) {
            // Laziness worked, we can stop checking that we're lazy enough.
            Log("has calmed down. Back to work.");
            Property.Set(self, "StTweqBlink", "AnimS", 0);
        }
    }

    function OnAIModeChange()
    {
        if (message().mode == eAIMode.kAIM_Dead) {
            Log("is brain dead. Back to work (or not).");
            // We're brain dead, stop caring.
            Property.Set(self, "StTweqBlink", "AnimS", 0);
            Object.RemoveMetaProperty(self, "M-RitualLazyExtra");
        }
    }

    function ExpireAwareness()
    {
        // First of all, if we're investigating, we let that happen for a while
        local invest_link = Link.GetOne("AIInvest", self);
        if (invest_link != 0) {
            // Find out why we're investigating.
            local awareness_link = Link.GetOne("AIAwareness", self, LinkDest(invest_link));
            if (awareness_link != 0) {
                local age = (GetTime() - Awareness_LastContactTime(awareness_link));
                if (age < kInvestigateMinAge) {
                    // Let the investigation continue.
                    Log("continuing fresh (" + age + "s) investigation: " + Awareness_Description(invest_link));
                    return;
                } else {
                    Log("investigation is getting old (" + age + "s): " + Awareness_Description(invest_link));
                }
            } else {
                Log("has no awareness link for its investigation.");
            }
        } else {
            Log("is not investigating.");
        }

        // Okay, we're going to destroy some links, so cache the iterator first just in case.
        local links = [];
        foreach (link in Link.GetAll("AIAwareness", self)) {
            links.append(link);
        }
        // Conditionally destroy means: destroy these if there are no other reasons to stay alert (live friendlies).
        local conditionally_destroy_links = [];
        local keep_count = 0;
        foreach (link in links) {
            // Basic evidence
            local dest = LinkDest(link);
            local level = Awareness_AlertLevel(link);
            local age = (GetTime() - Awareness_LastContactTime(link));
            local have_los = Awareness_HaveLOS(link);

            // Derived evidence
            local is_me = (dest == self);
            local is_hostile_team = AI_HostileTeam(AI_Team(self), AI_Team(dest));
            local is_same_team = (AI_Team(self) == AI_Team(dest));
            local is_dead = (AI_Mode(dest) == eAIMode.kAIM_Dead);
            local is_low_level = (level < 2);
            local is_old = (((level == 2) && (age >= kAwarenessMaxAge2))
                || ((level == 3) && (age >= kAwarenessMaxAge3)));

            // Draw conclusions:
            local ignore = false;
            local destroy = false;
            local expire = false;
            local conditionally_destroy = false;
            if (is_low_level) {
                // This link isn't keeping us alerted, so ignore it.
                Log("Ignoring low level: " + Awareness_Description(link));
                ignore = true;
            } else if (is_hostile_team) {
                if (is_old) {
                    // Guess it was just rats again.
                    Log("Destroying old (" + age + "s) hostile: " + Awareness_Description(link));
                    destroy = true;
                } else {
                    Log("Keeping recent (" + age + "s) hostile: " + Awareness_Description(link));
                }
            } else if (is_same_team) {
                if (is_me) {
                    if (is_old) {
                        // Well, I heard something, but that was a while ago.
                        Log("Destroying old (" + age + "s) heard: " + Awareness_Description(link));
                        destroy = true;
                    } else {
                        Log("Keeping recent (" + age + "s) heard: " + Awareness_Description(link));
                    }
                } else {
                    if (is_dead) {
                        // Friendly corpses aren't interesting once an investigation is over.
                        if (have_los) {
                            // But if it's still in sight, there's not much we can do,
                            // they *will* stay alert despite our best efforts.
                            Log("Friendly corpse is in sight, leaving it alone: " + Awareness_Description(link));
                        } else {
                            // But keep the link around so they don't forget and start investigating it again.
                            Log("Expiring friendly corpse: " + Awareness_Description(link));
                            expire = true;
                        }
                    } else {
                        // Friends don't let friends stay angry.
                        Log("Conditionally destroying friendly: " + Awareness_Description(link));
                        conditionally_destroy = true;
                    }
                }
            } else {
                // Neutral team? Can they even alert you? Don't care, let's get rid of it.
                Log("Destroying neutral: " + Awareness_Description(link));
                destroy = true;
            }

            // Act upon the conclusions.
            if (ignore) {
                // Well, what did you expect?
            } else if (destroy) {
                Link.Destroy(link);
            } else if (expire) {
                Awareness_Expire(link);
            } else if (conditionally_destroy) {
                conditionally_destroy_links.append(link);
            } else {
                ++keep_count;
            }
        }

        // When there's nothing to see, there's no reason to keep investigating.
        if (keep_count == 0) {
            Log("is destroying its investigation (if any).");
            local investLink = Link.GetOne("AIInvest", self);
            if (investLink!=0) {
                Link.Destroy(investLink);
            }

            // And destroy the conditional ones
            foreach (link in conditionally_destroy_links) {
                Log("Actually destroying conditional: " + Awareness_Description(link));
                Link.Destroy(link);
            }
        }

        if (keep_count == 0) {
            Log("CONCLUSION: No reason for " + Object_Description(self) + " to stay alert.");
            // HACK: sometimes despite all the awareness fudging, sometimes they don't calm
            // down soon enough. Shrug.
            // And if there's a body sitting right in front of them, they'll stay constantly on the
            // alert no matter what. Not much I can do about that.
        } else {
            Log("CONCLUSION: " + Object_Description(self) + " should stay alert, there's trouble out there.");
        }
    }

    // ---- Utilities

    function Awareness_Description(link)
    {
        return ("AIAwareness (level " + Awareness_AlertLevel(link) + ") "
            + Object_Description(self) + " -> "
            + Object_Description(LinkDest(link)));
    }

    function Awareness_AlertLevel(link)
    {
        return LinkTools.LinkGetData(link, "Level");
    }

    function Awareness_LastContactTime(link)
    {
        return (LinkTools.LinkGetData(link, "Time last contact") / 1000.0);
    }

    function Awareness_HaveLOS(link)
    {
        local flags = LinkTools.LinkGetData(link, "Flags");
        return ((flags & 0x08) != 0); // "HaveLOS"
    }

    function Awareness_Expire(link)
    {
        // Anything more than two minutes ago is old news.
        local a_long_time_ago = (floor((GetTime() - 120)).tointeger() * 1000);
        LinkTools.LinkSetData(link, "Level enter time", a_long_time_ago);
        LinkTools.LinkSetData(link, "Time last contact", a_long_time_ago);
        LinkTools.LinkSetData(link, "Last true contact", a_long_time_ago);
    }
}
