Separate asset plan based on the provided reference:

1. Generate `assets/art/backgrounds/room_background.png`
   - Background only
   - Keep the chair in frame
   - No character in the image

2. Generate `assets/art/character/companion_character.png`
   - Character only
   - Transparent background
   - Pose should match a seated position in the room scene

Why this split works:
- It matches the repo's VN layout: background layer plus character layer.
- It lets Godot animate or swap the character later without repainting the room.
- It preserves the fixed-camera composition described in the project docs.

Suggested generation settings:
- Model style: anime illustration / visual novel
- CFG guidance: medium-high
- Steps: medium-high
- Background aspect ratio: 16:9
- Character aspect ratio: 2:3 or 3:4

Godot import steps:
1. Place the generated room PNG in `assets/art/backgrounds/`.
2. Place the generated character PNG in `assets/art/character/`.
3. In `main_scene.tscn`, use the room image as the background texture.
4. In `companion_view.tscn`, replace the placeholder with the character PNG.
5. Scale the character so the head sits near the current head hotspot.
