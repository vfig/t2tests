QUESTION: can we use scripts to play motions backwards?


APPROACH 1: use Current Pose, script changes to the Frac property.

- FAIL: turns out cCreaturePoseProperty::DoPose() early exits when the sim is running, so this is a flat-out no. No changes to the Current Pose property will take effect at game time.


APPROACH 2: a fucking stupid idea, but can we use Time Warp and Puppet to play a motion at a much higher rate for one frame to get to the motion-frame that we want, and then next frame do the same?

- INTERESTING FAIL: unsurprisingly, the variable length of display frames means the puppet motion may play out shorter or longer than we wanted. so although the animation kinda plays out the way we wanted, it flickers horribly, and the worse the closer to the end of the animation we aim for.


RESULT: abandoned the initial question, and instead used the puppet approach to play to a random point in the motion every frame, for a wildly flickering, sort of Cradle-puppet turned up to 11 result. and changed the DetailAttach so the puppet is upside down for good measure. this could actually be an interesting horror mission ai, honestly?
