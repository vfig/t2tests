VOID EFFECT

!!! Try using ZeroGravRoom-like, together with adding velocity via timer and PhyState property to replicate this
!!! without all the water shenanigans.

Mission setup:

    - No VictoryCheck script! Having it on will make the breath hud and stuff happen. I don't understand why :(

    - Create a new Flow Group, that inherits from the base Flow Group (instead of a water or lava one).
        Group settings:
            y change/sec: -8.00 (because the entry to this flow brush is on the -y side.
            z change/sec: -0.50 (to cancel out the builtin buoyancy)
            texture name: vm (we're not using it otherwise, so it's easy to customise)
        Properties:
            Renderer/Water Flow Color Index: 3

Gamesys setup:

    # Makes void 'water surface' transparent when submerged
    - Texture Archetype "t_fam/WATERHW/vmin"
        Renderer/Water Texture Color:
            Color: 0,0,0
            Alpha: 0

    # Makes void 'water surface' transparent from outside
    - Texture Archetype "t_fam/WATERHW/vmout"
        Renderer/Water Texture Color:
            Color: 0,0,0
            Alpha: 0

    # Prevent "walking" along the void floor even when submerged
    - Texture Archetype "t_fam/core_1/Tile"
        Physics/Terrain/Friction: 0.00

Resource setup:

    # Replace sound when submerged (unfortunately it's hardcoded)
    - Save desired sound to snd/sfx/underwat.wav

    # Create a spinning fake skybox
    - Add fam/core_1/tile.mtl:
        render_pass
        {
            texture "env\acid"
            uv_source PROJECTION
            uv_mod SPIN 17
            no_mipmap
            render_material_only
        }

Notes:

    - I used fam/core_1/tile because I'm lazy and so didn't need to create and manage a new archetype.

    - Fog zone is possible, but tweaking needed so it doesn't end up revealing the fake skybox edges/corners
