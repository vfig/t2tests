Hasty demo of dynamically changing the "sky". Instead of the mission-defined sky (whether newsky or not) and SKY HACK texture, these walls are using NewDark materials to render a skybox instead of the actual texture. Because I'm lazy, I just used fam/core_1/cave here, but you should really use your own fam texture here instead (the actual fam texture doesn't matter much because it's only rendered within dromed). The important part here is the .mtl that defines the cubemap texture to use and PROJECTION uvs to draw as a skybox.

The actual sky swapping is done with a trivial squirrel script that calls Engine.SetEnvMapZone() to change the envmap zone texture. In this case, I'm just changing the global zone, but if you define different envmap zones you can change a different one instead. Also, if you use a different script library that can change envmap zones, that should probably work just as well instead of this squirrel script, if you don't want to use squirrel.

You can still use a newsky or old-style stars sky elsewhere in the mission if you like, just as you normally would.

Note that the env\cubemap.dpf and env\skycube.psd files are NOT needed for the mission to run, they're just source files that I kept in the same directory for convenience.
