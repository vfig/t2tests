This is investigating a bug, reproduced in miss1:

1. wait for the guard to patrol downstairs, and stop to IdleGesture
2. quicksave
3. quickload
4. wait for the guard to turn. when they do so, they fly up to the ceiling and get stuck.

miss2: workaround: move the guard to start on the lowest floor. rebuild pathfinding.
miss3: failed workaround: move the guard to start on the lowest floor. (no rebuild). flies up _immediately_!

[NB: i think this is happening in cGroundLocoManeuver::Execute()]
