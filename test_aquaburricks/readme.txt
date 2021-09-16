# AquaBurricks

An experiment in swimming burricks.

When the AquaBurrick enters the water, it gets M-AquaBurrickInWater added; when it returns to land, the metaprop is removed again. This metaprop should be used to control all swimming-specific behaviours, motions, and sounds.

IMPORTANT: when building pathfinding, ensure the underwater path brush is used:
    1. find the flood brush that extends way out of the water
    2. make it solid
    3. portalize
    4. build pathfinding
    5. make it flood again
    6. portalize again

## AI Behaviour

When the burrick is swimming, it should NOT use its burp attack. Instead, it should seek out nearby land that it can climb on, and burp from there (if still in range). If there is no nearby land, then maybe it should just generically flee. Possibly (maybe difficulty gated?) it could use a melee attack when in water, if suitable motions and HtoH support is added.

Current state of AI:

    - trying to wrangle the AI: Ranged Combat properties has resulted in a burrick that just floats frustrated in the water when trying to attack.

    - trying to use vantage-seeking behaviours didnt help (but maybe I just don't understand them?).

    - trying to abuse flee behaviours to make the burrick seek out land ended up with a burrick that reaches land and keeps on fleeing.

    STATUS: leave AI issues for later

Possible next steps:

    - clean up the flee properties and points, probably

    - use a script to respond to alert 3 and locate a nearby on-land point and path to it (using another metaprop to forcibly suppress combat abilities and just patrol? dunno)

    - research ranged ai behaviours to try to understand the properties better

    - look at existing FMs (Duncan Malveine; Equilibrium) that have combo ranged/melee enemies to understand how their ranged attacks are suppressed

## Motions

Current state of motions:

    - Successfully roundtripped motions through blender, and added a new motion to the schemas! Headbanging burrick uses Stand 0, Doof 0 (the Doof tag existed already, and was too good _not_ to use!)

Next steps for motions:

    - Make new motions for swimming burricks!
