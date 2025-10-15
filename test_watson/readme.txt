skacky--

This describes the summoning and search mode behaviour of Watson (i.e. Barlowe) in the `test_watson.cow` example mission in detail. The first two sections on FrobStim setup and Summonable AI you can skim over, as you probably have these all just fine already.

The main thing here is the Searching Behaviour details and the section on Searching Patrol Paths right at the end. Probably read the latter first after playing around with the example mission, to understand the gist of what is going on here. But all the other parts have commentary on what purpose they play in the whole setup.

This example is just a proposal, demonstrating one fairly simple way to make an AI appear to search around. Other more complicated approaches (but perhaps also more interesting for the player?) would be possible, but I prefer to try the simplest, most robust approach first. Regardless, I don't know enough about the broader context in your mission to tell if this behaviour is good enough or not: you will have to be the judge.

Finally, this does not include any room-triggered teleporting of the ComeHereWatson summon marker, for "tethering" Watson to the player's general area. But everything in this setup should be compatible with that. You might need to trigger the `WatsonStopSearchConv` conversation when you do the tether teleport, to kick Watson out of search mode so he chases down the newly teleported summon marker again (just like what happens when WatsonSummoner is frobbed). But search mode self-cancels, so he will eventually do that on his own anyway.

Note: *** marks values which you will likely want to adjust to tune behaviour.

Footnote: I use the name "Watson" in this example, because Alexander Graham Bell said "Come here, Watson". That's the joke. It's not much of a joke, really.


-----------------------
REVISION 0 (2025-10-13)
-----------------------


FrobStim setup
==============

This is a standard setup for stim-based inventory frobs; cf. https://www.ttlg.com/forums/showthread.php?t=120359&p=1715290&viewfull=1#post1715290 -- inventory-frobbable items have a FrobStim source; the receptron on Garrett reflects the stim back to the inventory item to handle with a FrobStim receptron.

1. new Stim archetype: `FrobStim`.

2. `Garrett` archetype.

    a) new Receptron:
        - Stimulus: FrobStim
        - No Min
        - No Max
        - Effect: Stimulate Object
        - Target: Source
        - Agent: Me
        - Edit Effect:
            * Stimulus: FrobStim
            * Multiply by: 1.0
            * Then Add: 0.0


Summonable AI
=============

Here I describe only the parts that relate to the summoning behaviour. Any additions or changes for the searching behaviour are described in the section below.

1. `Watson` AI (i.e. Barlowe):

    This is an AI who will continually try to go to a target object (thanks FireMage for the setup). By doing this continually, any pathfind failures won't matter much, as the AI will try again a short time later.

    a) AI > AI Core > Awareness capacitor:
        - Discharge time 1: 4000 ***
        - Discharge time 2: 8000 ***
        - Discharge time 3: 5000 ***

        This allows the AI to forget about Garrett quickly once it no longer senses him, so that it can return to chasing the summoning target.

    b) AI > AI Core > Efficiency Settings:
        - Enabled: FALSE

        Make sure the AI will still do all this stuff even if its on the other side of the map.

    c) AI > Ability Settings > Idle: Returns to Origin: FALSE

        Make sure the AI doesnt try to walk back to its starting point if it finds itself without a goal for a few moments.

    d) AI > Utility > Watch: Watch link defaults:
        - Watch kind: Self entry
        - Priority: High
        - Radius: 4
        - Height: 8
        - Required awareness: (0) None
        - Line requirement: None
        - Minimum alertness: (0) None
        - Maximum alertness: (1) Low
        - Link kill option: Don't kill
        - Kill like links: FALSE
        - No test once triggered: FALSE
        - Reuse delay: 5000 ***
        - Reset delay: 5000 ***
        - Step 1: Goto object
            * Argument 1: ComeHereWatson
            * Argument 2: Very Fast ***

        This makes the AI try once every five seconds to go to the named marker. By having max alertness 1, it will only do it when it is not currently investigating, in combat, or in "search mode" (see below).

        I use `Very Fast` here to make it run, but `Normal` for it to walk is fine instead.

2. `ComeHereWatson` Marker:

    Just a named Marker for now.

3. `WatsonStartConv` Marker:

    Holds the conversation that begins the whole summonable-Watson thing. While this conversation can be on the `ComeHereWatson` marker itself if you prefer, in this example I keep it separate in order to clarify that its purpose is distinct.

    a) AI > Conversations > Conversation; page 00:
        - Actor: ActorOne
        - Action 0: Remove link
            * Argument 1: ControlDevice
            * Argument 2: WatsonStartConv [i.e. the object with this Conversation on it]
            * Argument 3: @object

            Remove the CD link to this object so that the conversation cannot be triggered again (which would cause duplicate links).

        - Actor: ActorOne
        - Action 1: Add link
            * Argument 1: AIWatchObj
            * Argument 2: Watson
            * Argument 3: Watson

            Sets up the self-watch link with the preconfigured 'watch link defaults' from Watson itself.

    b) Scripts:
        - TrapConverse

    c) Link:
        - AIConversationActor
            * From: this marker
            * To: Watson
            * Data: 1

4. a "Sliding On/Off" lever; for this example only.

    Embedded in solid so as to be silent and not player-frobable. This lever auto-activates when the sim starts, kicking off the WatsonStartConv conversation. In this example we want Watson's behaviour to begin immediately, but in your mission you will want some other setup to kick off the WatsonStartConv conversation whenever is appropriate.

5. `WatsonSummoner` object (i.e. the dagger):

    a) Engine Features > FrobInfo:
        - World Action: None
        - Inv Action: Script
        - Tool Action: None

    b) Inventory > Type: Item

    c) Source:
        - Stimulus: FrobStim
        - Propagator: Contact
        - Intensity: 1
        - Shape:
            * Contact Types: Frob in Inv
            * Velocity Coeff: 0
            * Frob Time Coeff: 0

        Standard FrobStim source to be bounced back through Garrett to our Receptron.

    d) Receptron:
        - Stimulus: FrobStim
        - No Min
        - No Max
        - Effect: Teleport Object
        - Target: ComeHereWatson
        - Agent: Source
        - Edit Effect: ***

        Teleports `ComeHereWatson` to the player's location when the player frobs the summoner. Use the Effect parameters to offset it slightly from the player's location if preferred; but use only small offsets, otherwise it could be teleported inside solid if the player is standing beside a wall.


Searching Behaviour
===================

1. new Stim archetype: `WatsonStopSearchStim`.

2. new Metaproperty, beneath AI_Behaviors: `M-WatsonSearching`:

    This metaproperty is added to Watson to put it into "search mode", and then removed to cancel search mode. It self-removes periodically, to ensure Watson cannot get stuck in search mode forever.

    a) AI > AI Core > Alertness Cap:
        - Max level: (3) High
        - Min level: (2) Moderate
        - Min relax after peak: (0) None

        We force the AI into alert 2 when searching. Most importantly, this ensures that the summoning behaviour is temporarily suspended while in search mode. But also this sometimes triggers the AI to go into the stock Investigate behaviour on its own, which doesn't hurt. If desired you can disable Investigate behaviour with the AI > Ability Settings > Investigation Style property.

    b) AI > Ability Settings > Patrol: Does Patrol: TRUE

    c) AI > Ability Settings > Patrol: Random sequence: TRUE

        Once in search mode, we want Watson to wander more or less at random around the area, apparently looking for the player. We use a random patrol to achieve this, so that the points that he wanders to can be placed in suitable locations by you.

    d) AI > Responses > Alert response:
        - Alert Level: (3) High
        - Priority: Absolute
        - Step 1: Add/Remove Meta-property
            * Argument 1: Remove
            * Argument 2: M-WatsonSearching
            * Argument 3: Watson

        Ensure we exit search mode if reaching high alert. This prevents the hilarious situation where Watson would be in combat but still play the search animations while trying to advance on the player.

    e) Motions > ActorTagList:
        - tags: Search 0 ***

        This makes the AI use the "searching" animations while walking around, so it looks like it is Investigating even when it is just patrolling. (This is the same way the guards in the city streets in the "return home" part of Assassins fake being in Investigate behaviour.) Remove or change this property if you would prefer normal walking or some other animation set.

    f) Source:
        - Stimulus: WatsonStopSearchStim
        - Propagator: Radius
        - Intensity: 0
        - Shape:
            * Radius: 1.0
            * Flags: None
            * Dispersion: None
        - Life Cycle:
            * Flags: No Max Firings
            * Period: 45000 ***
            * Max Firings: 1
            * Intensity Slope: 1

        This self-stim fires immediately when search mode begins with zero intensity, but then keeps on firing at intervals with the intensity increasing. Together with the receptron below, this makes search mode cancel itself after 45 seconds have passed; at which point (if not in combat), Watson will run back to the summon marker. Customise the period if you want search mode to last a longer or shorter time.

    g) Receptron:
        - Stimulus: WatsonStopSearchStim
        - Min Intensity: 1
        - No Max
        - Effect: Remove MetaProperty
        - Target: Me
        - Agent: M-WatsonSearching

3. `WatsonStopSearchConv` Marker:

    Holds a conversation that forces Watson to leave search mode. (This ought to have been achievable with Receptrons only, but for whatever reason the Remove MetaProperty effect was not working when the target was Watson and neither the source nor receiver of the stim. Hence this object and its button.)

    a) AI > Conversations > Conversation; page 00:
        - Actor: ActorOne
        - Action 0: Add/Remove Meta-property
            * Argument 1: Remove
            * Argument 2: M-WatsonSearching
            * Argument 3: Watson

    b) Scripts:
        - TrapConverse

    c) Link:
        - AIConversationActor
            * From: this marker
            * To: Watson
            * Data: 1

4. `WatsonStopSearchBtn` Button:

    Embedded in solid so as to be silent and not player-frobable. Kicks off the WatsonStopSearchConv conversation to force Watson out of search mode.

    c) Link:
        - ControlDevice
            * From: this button
            * To: WatsonStopSearchConv

5. add to `ComeHereWatson`:

    a) AI > Utility> Watch: Watch link defaults:
        - Watch kind: Self entry
        - Priority: High
        - Radius: 8 ***
        - Height: 8 ***
        - Required awareness: (0) None
        - Line requirement: Line of sight [see REVISION 1 below]
        - Minimum alertness: (0) None
        - Maximum alertness: (1) Low
        - Link kill option: Don't kill
        - Kill like links: FALSE
        - No test once triggered: FALSE
        - Reuse delay: 3000
        - Reset delay: 3000
        - Step 1: Add/Remove Meta-property
            * Argument 1: Add
            * Argument 2: M-WatsonSearching
            * Argument 3: Watson

        Adjust the radius here (and perhaps the height) if Watson is entering search mode too far from the summon marker, or too close to it.

6. add to `WatsonStartConv`:

    a) add to: AI > Conversations > Conversation; page 00:
        - Actor: ActorOne
        - Action 2: Add link
            * Argument 1: AIWatchObj
            * Argument 2: ComeHereWatson
            * Argument 3: Watson

            Sets up a watch link for Watson to enter search mode when nearing the summon marker, using the defaults on the summon marker itself.

7. add to `WatsonSummoner`:

    a) Receptron:
        - Stimulus: FrobStim
        - No Min
        - No Max
        - Effect: Frob Object
        - Target: WatsonStopSearchBtn

        This receptron should come after the `Teleport Object` receptron. This forces Watson out of search mode immediately (if it was searching) so that it will come to the summon marker without delay (although if Watson is in alert 2 or 3, that will still have to cool off first).


Searching Patrol Paths
======================

In each general area where Watson may be summoned to or tethered to, add TrolPts for the various locations where he might reasonably look for the player, and link them in a loop with AIPatrol links.

How you place these is up to you; you might keep each loop within a single room, or have one loop go through nearby rooms as well. Note that the TrolPts do *not* have to mark out an actual path through doorways and such, as Watson will be on random patrol and thus pathfind directly from one TrolPt in the loop to another randomly selected TrolPt.

What will happen is, when Watson reaches the ComeHereWatson marker, it will enter search mode and find the nearest TrolPt to wherever he is, and start randomly moving between the other TrolPts in its loop. If these search patrol paths are placed reasonably densely, most of the time he will glom onto one of those.

However it might happen that he gloms onto some other patrol path intended for a guard or other AI (depending on exactly where the summon marker was placed and where Watson was when entering search mode); this would likely make him wander right out of the room again. This may not be a problem: firstly it makes Watson's behaviour a little more unpredictable to the player; and secondly the search mode will automatically be cancelled before long, returning Watson to the summon marker again; so he will not get stuck on this other patrol path forever.

Finally, you can add other behaviours to these Watson-specific TrolPts if you want, just as you might use TrolPausePts or the various TBP embellishments in a normal guard patrol. As long as such a behaviour will run at alert 2 (but not 3), it should fit in just fine.

--vfig (2025-10-13)


-----------------------
REVISION 1 (2025-10-15)
-----------------------


With Barlowe (but not seen in this example with Watson), often the watch on the summon marker would fail to trigger. There is no detailed debugging for AIWatchObj links, so this is only a best guess supported by testing, but it appears that the line of sight condition is not being met some of the time. My guess is this is due to much faster movement and/or the rather more quadrupedal motion of Barlowe than the human guard.


1. Change `ComeHereWatson`:

    a) AI > Utility> Watch: Watch link defaults:
        - Line requirement: None


-----------------------
REVISION 2 (2025-10-??????????)
-----------------------


use stim trigger for search metaprop pushing (since this is 1.28)
squirrel-based awareness coolerdowner?
