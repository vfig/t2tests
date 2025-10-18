The idea here was to see if we could get a "Junk" item (such as a flare) to go into Tool mode (in the center of the screen) if and only if looking at a thing in the world that it can be used with.

Short answer: no; because if a Junk item is being held, then no world focus messages are set at all.

Long answer: yes:

    While toggling an inv-objects InvType between Junk and Item/Tool works, without the focus messages, we cant reliably decide when to make that switch happen.

    WELL: the switch from Tool back to Junk need only happen when we look away from the world-object, i.e. we WILL get a WorldDeSelect message at that point, because the inv-object is a Tool at that point. So... if instead we use a raycast test to check if we are looking at a suitable world-object (e.g. via a SimSmallRadius Blink tweq on the world-object itself), then we could BOTH switch the world-object into FocusScript mode and switch the inv-object into Tool mode*????

    Of interest: `set disable_modal_tool_frob` makes tool items automatically go into active (center of screen) when looking at a world-frobbable object (regardless of if the tool works with it or not), instead of requiring the player to frob to toggle tool-active on and off.

    (* AND maybe toggle disable_modal_tool_frob?? -- no, see nut for why that doesnt work)


ANYWAY theres still issues (see bugs noted in nut). theres too much awkward ui state wrangling that is unreliable!
