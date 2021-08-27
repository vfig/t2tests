the idea here was to see if i could make a water surface that was frobbable.

you would pick up a bucket (for example), and toolfrob it with the water to fill it. (or drop it in the water, but thats clunkier)

flow group objects themselves live at 0,0,0 and are not rendered, so frobbing them is out.

using a bitmap decal on the surface is reasonable.

but i only want it to have 'FrobInfo: World Script' while you have the bucket tool selected. so that will have to be done with a script on the bucket that oninvselect/oninvdeselect wildcard-adds/removes a M-FrobbableWater to all the water surfaces objects. then, M-FrobbableWater when toolfrobbed exudes a water stim onto the source object.

the bucket, when it gets a sufficient water stim, can swap itself with a filled bucket. (either swapping objects, or changing metaprops and model name). the filled bucket is then a tool that deploys that water stim and empties itself again.
