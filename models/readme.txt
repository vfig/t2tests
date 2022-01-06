cashreg.mis
-----------

Cash register models. Use however you like.
  - cashreg1: cash register, with cash drawer as a jointed submodel. For use as
        a container.
  - cashreg1a: cash register, without cash drawer. For use as a lockbox.
  - cashreg1b: cash drawer. For use as a door.

Textures:
  - cashreg.png: You only need this one.
  - cashreg_hd.png: Alternative, higher resolution texture. If you find the
        default texture too blurry, rename this one to cashreg.png to use it
        instead.

Joints:
  - 1: Handle (rotating)
  - 2: Paper tape spool (rotating)
  - 3: Cash drawer (translating)

See cashreg.mis for an example configuration. The register on the left is a
lockbox and door combination; the one on the right is a container.

Note that the FrobInert metaproperty manipulation in the lockbox/door example
is kinda broken; it successfully removes the metaproperty when the door is
first opened, but doesn't re-add it when closing the door. I am too unfamiliar
with NVScript to figure out how to fix this!
