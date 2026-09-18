#!/usr/bin/env bash
# Collect every Yua redesign draft into art_source/yua_redesign/ for review.
#   <round>/character/  transparent PNG, drops straight into the game
#   <round>/in_scene/   the same art photographed in the live room
#   _sheets/            the side-by-side comparison sheets
set -u
P="D:/Project Chill/project-chill"
SP="C:/Users/zengh/AppData/Local/Temp/claude/D--Project-Chill-project-chill/37e5a5a4-ea48-4122-9548-2366b6f43059/scratchpad"
A="$P/art_source/yua_redesign"
mkdir -p "$A/_sheets" "$A/_reference"

copy_round() {
  local src="$1" dest="$2"; shift 2
  mkdir -p "$A/$dest/character" "$A/$dest/in_scene"
  for n in "$@"; do
    [ -f "$SP/$src/${n}.png" ] && cp "$SP/$src/${n}.png" "$A/$dest/character/${n}.png"
    [ -f "$SP/$src/fixed_${n}.png" ] && cp "$SP/$src/fixed_${n}.png" "$A/$dest/in_scene/${n}.png"
  done
  echo "$dest: $(ls "$A/$dest/character" | wc -l) art, $(ls "$A/$dest/in_scene" | wc -l) in-scene"
}

copy_round builds   "1_accessory_swaps"  seaglass apron nightshift writer
copy_round redesign "2_first_redesigns"  ponytail hoodie sailor braids pixie hime
copy_round bold     "3_bold_world"       ponytail aquarium moonclerk lighthouse twotone fisherman
copy_round wild     "4_hair_colour"      seafoam splitdye moonsilver wolfcut mori inkbob
copy_round pony     "5_ponytail_ten"     seafoam inkteal aquarium bookshop braided sporty moonlit edge hoodie apricot

# round 1 and 2 stored their keyed art under *_magenta names in some cases
for n in seaglass apron nightshift writer; do
  [ -f "$A/1_accessory_swaps/character/${n}.png" ] || cp "$SP/builds/${n}.png" "$A/1_accessory_swaps/character/${n}.png" 2>/dev/null
done

cp "$SP/pony/pony_grid.jpg"            "$A/_sheets/round5_ten_ponytails.jpg"       2>/dev/null
cp "$SP/wild/wild_fixed_strip.jpg"     "$A/_sheets/round4_hair_colour.jpg"         2>/dev/null
cp "$SP/wild/forearms.jpg"             "$A/_sheets/round4_forearm_detail.jpg"      2>/dev/null
cp "$SP/bold/forearms.jpg"             "$A/_sheets/round3_forearm_detail.jpg"      2>/dev/null
cp "$SP/builds/builds_in_scene.jpg"    "$A/_sheets/round1_accessory_swaps.jpg"     2>/dev/null

cp "$SP/builds/current_scene.png"      "$A/_reference/current_yua_in_scene.png"    2>/dev/null
cp "$P/assets/art/character/yua_at_player.png" "$A/_reference/current_yua_art.png" 2>/dev/null
cp "$SP/yua_noarms.png"                "$A/_reference/armless_reference.png"       2>/dev/null

echo "total: $(find "$A" -name '*.png' -o -name '*.jpg' | wc -l) files, $(du -sh "$A" | cut -f1)"
