MOTIONS <- {

    /* Stock motions from a list by Yandros: */
    STOCK=[
        {name="Default", tags=[
            "Conv 1", // raise left hand
            "Conv 2", // lean back
            "Conv 3", // shuffle from side to side
            "Conv 4", // shake arms in frustration
        ]},
        {name="Other", tags=[
            "Conv 5", // lean forward
            "Conv 6", // nod head
            "Conv 7", // move arms up and down low
            "Conv 8", // turn head right
            "Conv 9", // arms behind back
        ]},
        {name="Conv 1-9", tags=[
            "Conv 1", // raise left hand
            "Conv 2", // lean back
            "Conv 3", // shuffle from side to side
            "Conv 4", // shake arms in frustration
            "Conv 5", // lean forward
            "Conv 6", // nod head
            "Conv 7", // move arms up and down low
            "Conv 8", // turn head right
            "Conv 9", // arms behind back
        ]},
        {name="Conv 10-19", tags=[
            "Conv 10", // hands together at front
            "Conv 11", // arms crossed
            "Conv 12", // arms wide then right hand up low
            "Conv 13", // walk forward, wave right hand, hesitate, step back, then run right
            "Conv 14", // lie on back, turn head from side to side
            "Conv 15", // waving arms mid
            "Conv 16", // look up then down then shake arms out mid
            "Conv 17", // shake arms left to right
            "Conv 18", // shake arms low then shrug
            "Conv 19", // shake arms in agreement
        ]},
        {name="Conv 20-29", tags=[
            "Conv 20", // shake right hand and shake head
            "Conv 21", // lying down, shake left arm then fall dead
            "Conv 22", // gesture with hands for a long time
            "Conv 23", // move head
            "Conv 24", // right hand up and down
            "Conv 25", // two arms up and out
            "Conv 26", // right hand up and down and shake head
            "Conv 27", // left hand up and down, nod head
            "Conv 28", // both hands up and down mid
            "Conv 29", // both hands up and down, turn in a circle, raise arms, then right arm forward (the ranting Hammerite)
        ]},
        {name="Conv 30-39", tags=[
            "Conv 30", // put hands on hips and lean forward
            "Conv 31", // right hand forward, left hand on hip, then lean forward
            "Conv 32", // wave arms out, then hands on hips and lean forward
            "Conv 33", // hands on hips, lean forward, then shake head
            "Conv 34", // right hand out, left hand on hips, move head, then right hand to hip
            "Conv 35", // hands on hips leaning forward
            "Conv 36", // lies down, sifts position (as if uncomfortable)
            "Conv 37", // nods head (bow)
            "Conv 38", // raise left hand and nod (traditional salute)
            "Conv 39", // left hand across chest, head up (imperial salute)
        ]},
        {name="Conv 40-42", tags=[
            "Conv 40", // raise left hand, head nods to left
            "Conv 41", // raise both hands slightly
            "Conv 42", // crouch, then stand
        ]},
        {name="Foo and friends", tags=[
            "Conversation 0, Foo", // salute
            "Conversation 0, Foo, Bar", // lean forward
            "Conversation 0, Foo, Baz", // nod head
            "Conversation 0, Foo, Bar, Baz", // turn head right
            "Conversation 0, Foo, Quux", // hands together in front
            "Conversation 0, Bar", // lean back
            "Conversation 0, Bar, Baz", // arms up and down low
            "Conversation 0, Bar, Quux", // cross arms
            "Conversation 0, Baz", // shake arms in frustration
            "Conversation 0, Baz, Quux", // hold arms out low
            "Conversation 0, Quux", // <dd>arms behind back
        ]},
        {name="Sitting/Lying", tags=[
            "Stand2Sit", // sits down from standing
            "Sit2Stand", // stands up from sitting (quickly)
            "Sit2Lie", // goes from sitting to lying
            "Lie2Stand", // from lying to sitting
        ]},
        {name="Standing", tags=[
            "Stand 0", // hold still
            "Stand 0, Halt 0", // sudden stop
            "Stand 0, Halt 0, NearHazard 0", // jump back
            "Stand 0, Halt 0, OnStairs 0", // leans forward
            "Stand 0, Wheel 0", // ???
            "Stand 0, LeaningLeft 0", // ???
            "Stand 0, LeaningRight 0", // ???
            "Stand 0, Crouching 0", // ???
            "Stand 0, Search 0", // ???
            "IdleGesture 0", // fidget
        ]},
        {name="Items and Frobs", tags=[
            "ReadyItem 0", // hand to left side
            "ReadyItem 0, ItemSword 0", // fighting stance
            "ReadyItem 0, ItemBow 0", // hand to right side
            "WorldFrob 0, AtWaist 0", // push button
            "WorldFrob 0, AtWaist 0, Lever 0", // pull big floor lever
            "WorldFrob 0, AtWaist 0, Door 0", // turn knob
            "WorldFrob 0, AtWaist 0, BellPull 0", // pull cord (T1/G only?)
            "WorldFrob 0, OnFloor 0", // not in T2
            "WorldFrob 0, AtChest 0", // not in T2
        ]},
    ],

    /*
    // TODO: fix these (some have multiple directions) and organise them?
    UNORGANISED=[
        {name="Jumping", tags=[
            "Jumping 0", // garret
            "Jumping 0, LocoUrgent 0<i>, Direction &lt;&gt;</i>", // garret
        ]},
        {name="Walking", tags=[
            "Locomote 0<i>, Direction &lt;1-4&gt;</i>", // walk
            "Locomote 0, LocoUrgent 0<i>, Direction &lt;1-4&gt;</i>", // run
            "Locomote 0, Search 0", // walk holding out weapon
            "Locomote 0, Climbing 0", // garret
            "Locomote 0, Crouching 0", // garret
        ]},
        {name="Dying", tags=[
            "Crumple 0, Knockout 0", // on back
            "Crumple 0, Die 0<i>, Direction &lt;1-4&gt;</i>", // on front
            "Crumple 0, Die 0, IsConfined 0", // to knees then front
            "Crumple 0, Die 0, OnStairs 0", // curl up into a ball
        ]},
        {name="Searching and Finding", tags=[
            "Search 0, Scan 0", // look from side-to-side
            "Search 0, Peek 0<i>, Direction &lt;1-3&gt;</i>", // lean forword
            "Discover 0, PointOut 0<i>, Direction &lt;0,5-6&gt;</i>", // point at something, Direction 0 points at something far away.
            "Discover 0, Recoil 0<i>, Direction 4</i>", // jump back (or forward)
            "Discover 0, Recoil 0, IsConfined 0", // step back
            "Discover 0, Thwarted 0", // be frustrated
            "Discover 0, Salute 0", // raise left hand
            "Discover 0, Challenge 0", // shake fist
        ]},
        {name="Stuns and Damage", tags=[
            "Stalled 0, Poisoned 0", // choking
            "Stalled 0, Stunned 0<i>, Long 0</i>", // sway from side-to-side
            "Stalled 0, Blinded 0", // arms raised
            "Stalled 0, Flail 0<i>, Long 0</i>", // seizure
            "Stalled 0, Flail 0, InWater 0", // raised arms, then collapse to knees
            "Stalled 0, Flail 0, InAir 0", // ???
            "Stalled 0, Rebalance 0", // over-exagerated acting like there's an earthquake
            "ReceiveWound 0<i>, Direction &lt;1,2,7,8&gt;</i>", // ouch
            "ReceiveWound 0, SevereWound 0<i>, Direction &lt;1,2,7,8&gt;</i>", // ouch!?
        ]},
        {name="Attacks", tags=[
            "RangedCombat 0", // cast spell (or fire arrow)
            "MeleeCombat 0, Stand 0", // be still
            "MeleeCombat 0, Locomote 0<i>, Direction &lt;1-4&gt;</i>", // move
            "MeleeCombat 0, Locomote 0, LocoUrgent 0<i>, Direction &lt;1-4&gt;</i>", // dodge
            "MeleeCombat 0, Block 0<i>, Direction &lt;1,2,5,6&gt;</i>", // block
            "MeleeCombat 0, Attack 0, Direction &lt;0,5,6&gt;", // swing sword
            "MeleeCombat 0, Attack 0, SpecialAttack 0", // two-handed overhead bash
        ]},
    ],
    */

    /* Additional motions from Shadowspawn's GMDB: */
    GMDB=[
        {name="Conv 50-69 (Talking)", tags=[
            "Conv 50", // *Sword drawing, already mapped to Misc 3
            "Conv 51", // Starts with arms folded, slowly returns to normal standing
            "Conv 52", // Stands with arms folded, nods 3 times, long sequence
            "Conv 53", // Starts with arms folded, returns to normal standing (quicker than BH114002)
            "Conv 54", // With arms folded, shakes head no
            "Conv 55", // Starts with arms folded, goes to hands on hips
            "Conv 56", // Starts with hands behind back, returns to normal pose
            "Conv 57", // Stands with hands behind back, nods slightly
            "Conv 58", // Stands with hands on hips
            "Conv 59", // With hands on hips, shakes head no
            "Conv 60", // Waves with right hand, shakes head
            "Conv 61", // Stands with arms out sideways, bent from elbow
            "Conv 62", // Cupping something in right hand, points with left, shakes head
            "Conv 63", // Cupping something in right hand, extends right hand (low)
            "Conv 64", // Cupping right hand, takes (key?) from belt with left hand
            "Conv 65", // left hand pulls something off right hand side, belt level
            "Conv 66", // Same as BH114720, but turns head to see - mapped to ReadyItem 0, ItemBow 0
            "Conv 67", // Another "I don't Know" motion
            "Conv 68", // Lowers arms from Zombie position to side
            "Conv 69", // Raises arms from side to Zombie position
        ]},
        {name="Conv 70-80 (Dance/Bar)", tags=[
            "Conv 70", // zomdanc2
            "Conv 71", // zomdanc1
            "Conv 72", // zomdance
            "Conv 73", // Dances while kneeling
            "Conv 74", // Dance the macarena
            "Conv 75", // Robot like dance
            "Conv 76", // Female dancing in bar, fixes hair, looks like talking to someone
            "Conv 77", // Dancing at bar, drinks a shot
            "Conv 78", // Holding drink in bar, motions with left hand, then slowly drinks with right.
            "Conv 79", // Sitting on bar stool, eating or drinking.
            "Conv 80", // Staggering drunk standing
        ]},
        {name="Conv 81-87 (Backing up)", tags=[
            "Conv 81", // Jumps back, arms out for balance. On narrow space?
            "Conv 82", // Carefully steps back, arms guarding in front. On narrow space?
            "Conv 83", // Backs up and points forward with right hand
            "Conv 84", // Leaps back, then backs away
            "Conv 85", // Violently jumps back from something
            "Conv 86", // Steps backward, crouching, as if trying to hold back something
            "Conv 87", // Walks forward, raises hands, cowers backward
        ]},
        {name="Conv 88-95 (Lying down)", tags=[
            "Conv 88", // Lying on back, begging for water.
            "Conv 89", // Lying on ground, reaches upward with left hand
            "Conv 90", // From lying on back, raises upper body on elbows, then looks right
            "Conv 91", // From lying on back with upper body up, lies back down (like passing out)
            "Conv 92", // Lying on side, raised up on left arm, move right arm around
            "Conv 93", // Looks like a continuation of bh114325, moves head like listening
            "Conv 94", // Just lying on back, short
            "Conv 95", // Just lying on back, short, different orientation
        ]},
        {name="Conv 96-100 (Keyboard)", tags=[
            //    Typing motions (or playing keyboard?)
            "Conv 96", // Sitting, both hands typing
            "Conv 97", // Sitting, stopped typing, moves head slightly
            "Conv 98", // Sitting, extends hands, get ready to type
            "Conv 99", // Sitting, pulls hands away from keyboard
            "Conv 100", // Stands typing
        ]},
        {name="Conv 101-111 (Frobbing)", tags=[
            "Conv 101", // Pushes buttons, then pulls lever; at eye level.
            "Conv 102", // Throwing dice at craps table.
            "Conv 103", // Moves forward, turning right, pushing at panel. Backs up to start.
            "Conv 104", // Rears back, and taps forward, like tapping someone on the chest
            "Conv 105", // Push buttons at head level, then reach down and pick up something
            "Conv 106", // Shakes right hand up high
            "Conv 107", // Adjusts something at head level, then turns left and pushes button
            "Conv 108", // Puts right hand up, as if to halt someone
            "Conv 109", // Reaches forward with right hand, pushes buttons
            "Conv 110", // Strikes with right hand, tries to push something away, then looks partly subdued.
            "Conv 111", // Looks stunned, looks at right hand, pushes some buttons, then steps forward and falls to knees
        ]},
        {name="Conv 112-119 (Kneeling)", tags=[
            "Conv 112", // Kneeling, casting spell or pouring two bottles into something
            "Conv 113", // Kneeling and rising motion (shooting from cover)
            "Conv 114", // Timid walk, kneels, freaks out, pulls hair
            "Conv 115", // Shaking, falls to his knees. (like an earthquake)
            "Conv 116", // Grabs stomach, vomiting. Falls to knees
            "Conv 117", // Crying, falls to knees
            "Conv 118", // Bends over, looks like petting something.
            "Conv 119", // Walks forward, stops suddenly, looks down and kneels, touches something on the ground, stands up shaking hand (trying to get something off of it)
        ]},
        {name="Conv 120-147 (Standing/Walking)", tags=[
            //     Standing and walking motions
            "Conv 120", // Attentively looking slightly down, like watching a rat
            "Conv 121", // Slides forward with right arm outstretched. Breaks off and steps back.
            "Conv 122", // Bravely pushes away twice, then cowers as looking up at something
            "Conv 123", // Looks like walking a line quick
            "Conv 124", // Shakes hands quickly in front of chest
            "Conv 125", // Jogging forward, no progress (treadmill?)
            "Conv 126", // Turns right and left while holding right arm level with belt
            "Conv 127", // Turns slightly to left, raises hands to shoulder height
            "Conv 128", // Looks like talking, extends both arms at waist to left, then turns right and puts right hand to mouth.
            "Conv 129", // Slides left, right arm high and outstretched. Then walks back to start
            "Conv 130", // Turns right, holds hands apart (Like: "The fish was that big")
            "Conv 131", // Looks left, returns to looking straight ahead
            "Conv 132", // Looks a little startled, looks left and behind, returns to idle
            "Conv 133", // Looks right and left, confused.
            "Conv 134", // Walking forward slowly, uses right hand to push someone out of the way
            "Conv 135", // Nervously looks left
            "Conv 136", // Nervously moves around, looking left and right
            "Conv 137", // Nervously looks around
            "Conv 138", // More nervous idling
            "Conv 139", // Looks down, right hand slightly raised, wobbles
            "Conv 140", // Awkward walk, glances behind
            "Conv 141", // Electrocuted, standing
            "Conv 142", // Nervous walk, tip toed, defensive.
            "Conv 143", // Walks in defensive posture, hands up. Returns to start
            "Conv 144", // Reaches over right shoulder with both hands and hurls something away
            "Conv 145", // Walking carefully, looking left and right
            "Conv 146", // Funny walk
            "Conv 147", // Walks, looking left, right, and behind
        ]},
        {name="Conv 148-161 (Cinematic)", tags=[
            "Conv 148", // Hold baby out to be taken or saved. Keeps reaching out.
            "Conv 149", // Dribbles basketball and then shoots
            "Conv 150", // Slowly dribbles basketball, then moves left and right
            "Conv 151", // Crawling on hands and knees
            "Conv 152", // Looks like he's checking his pockets, then turns around and looks behind him. Right foot is turned badly.
            "Conv 153", // Reeling from an explosion, slow
            "Conv 154", // Reacting to attack, rats maybe?
            "Conv 155", // Hangs head, extends arms out forward (ok, put the chains on me), then drops them
            "Conv 156", // Taking a shower
            "Conv 157", // Head and hands move as if singing
            "Conv 158", // Bats at head like being attacked by bees
            "Conv 159", // Check wrist watch (slowly)
            "Conv 160", // Moves right hand back and forth, like wiping a counter
            "Conv 161", // Wipes counter, waves someone away, returns to wiping
        ]},
        {name="Conv 162-172 (Hits/Damage)", tags=[
            //     Hits
            "Conv 162", // Hit in left eye, staggers back, then falls backward
            "Conv 163", // Hit hard in left shoulder
            "Conv 164", // Hard hit to stomach
            "Conv 165", // Hit hard, recoils back
            "Conv 166", // Upper body sways around. (hit or a dance step)
            "Conv 167", // Stunned or bad dancing
            "Conv 168", // Looks like hit in head
            "Conv 169", // Bigger hit than mdwrwnd1
            "Conv 170", // Very serious hit in head
            "Conv 171", // Big hit, wobbles around
            "Conv 172", // Looks like re-balancing?
        ]},
        {name="Conv 173-191 (Sick/Dying)", tags=[
            "Conv 173", // Shivering / dying while upright
            "Conv 174", // Dying motion, looks like got hit in the chest
            "Conv 175", // Die forward, Poisoned or shot in stomach
            "Conv 176", // Death scene, reaching forward
            "Conv 177", // Quick dying, falling backward
            "Conv 178", // Die moving forward
            "Conv 179", // Die on back, too quick
            "Conv 180", // Hand goes to mouth, then crumples
            "Conv 181", // Unsteady on feet, leans head back, looks confused
            "Conv 182", // Heaving. Coughing or vomiting. Right hip distorts
            "Conv 183", // Grabs stomach, vomiting. Falls to knees
            "Conv 184", // Leans forward, hanging and shaking head
            "Conv 185", // Turns around and falls over (dies). In chair
            "Conv 186", // Puts hand to side (like wounded), falls forward, dying
            "Conv 187", // Death scene. Shakes with arms open, falls forward, rolls onto back
            "Conv 188", // Death scene, falls forward, arms out
            "Conv 189", // Takes hit, flies backward and down on back
            "Conv 190", // Holds stomach, hunches over, wobbles a little
            "Conv 191", // Holds stomach, looks dazed, turns around 180
        ]},
        {name="Conv 192-194 (Poses)", tags=[
            "Conv 192", // Looks like ballerina pose and movement
            "Conv 193", // Short motion, ballerina pose
            "Conv 194", // Could be used for hung prisoner
        ]},
    ],
};
