this was investigating how pathfinding reacts to creature sizes.

you can set the Creature Size value in the gamesys vars so that pathfinding generates more links -- but it will cause problems for ais that are actually bigger than that: they will pathfind with links that they cannot physically walk along.

there are very few bits available for pathfinding links. Small Creatures is about the only one -- but it is not applied here. if i **really** wanted to pursue this path, i could in theory write a custom tool to add the Small Creatures bit to all links that are too small for humans...