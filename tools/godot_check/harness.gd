extends SceneTree
##
## Headless test harness for Project Chill.
##
## Boots the REAL main scene with no window, drives it the way a player would
## (click Yua, pick a choice, run the focus timer to completion), then prints a
## short PASS/FAIL report and quits.
##
## Not meant to be run by hand — call it through check.ps1, which also protects
## the owner's real save file. Direct form, for reference:
##
##   godot --headless --path <project> --script res://tools/godot_check/harness.gd \
##         -- --scenario=smoke --fresh
##
## Scenarios live in tools/godot_check/scenarios/*.gd. Each is a plain object
## with `const DESC` and `func run(g) -> void`, where `g` is this harness.
##

const MAIN_SCENE_PATH := "res://scenes/main/main_scene.tscn"
const SCENARIO_DIR := "res://tools/godot_check/scenarios/"
const SAVE_PATHS := [
	"user://data/saves/player_profile.json",
	"user://player_profile.json",
]
## Hard stop so a scenario that waits on something that never happens cannot
## hang the run forever. The wrapper has its own outer timeout as a backstop.
const FRAME_BUDGET := 40000
const DEFAULT_TIMEOUT_SECONDS := 90.0

var game: Node = null
var passed: int = 0
var failed: int = 0

var _scenario_id: String = ""
var _frames_used: int = 0
var _aborted: bool = false
var _ai_enabled: bool = false
var _opts: Dictionary = {}
var _shot_dir: String = ""
var _shot_count: int = 0


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

func _initialize() -> void:
	var opts := _parse_user_args()
	_opts = opts
	_shot_dir = str(opts.get("shot-dir", ""))

	if opts.has("list"):
		_list_scenarios()
		quit(0)
		return

	_scenario_id = str(opts.get("scenario", "smoke"))
	var scenario_path := SCENARIO_DIR + _scenario_id + ".gd"
	if not ResourceLoader.exists(scenario_path):
		print("HARNESS FAIL  unknown scenario '%s'" % _scenario_id)
		_list_scenarios()
		quit(2)
		return

	_start_watchdog(float(opts.get("timeout", DEFAULT_TIMEOUT_SECONDS)))

	# Tests start from a clean save by default, so results do not depend on how
	# far the owner happens to have played. It must happen BEFORE the scene loads —
	# wiping afterwards leaves the already-loaded state in memory, which silently
	# makes a "first run" test run as a returning player. check.ps1 backs up and
	# restores the real save around the whole run. Pass --keep-save to opt out.
	if not opts.has("keep-save"):
		wipe_save()

	# Typed replies route to the real AI provider unless we say otherwise, which
	# would make tests slow, non-deterministic and billable. Off by default;
	# pass --ai to exercise the live path deliberately.
	_ai_enabled = opts.has("ai")

	var scenario: Object = load(scenario_path).new()

	# Pure static checks (lint) skip the scene entirely, so they still run — and
	# still report — when the game is too broken to boot.
	var needs_game := true
	var constants: Dictionary = scenario.get_script().get_script_constant_map()
	if constants.has("NEEDS_GAME"):
		needs_game = bool(constants["NEEDS_GAME"])

	if needs_game and not await _mount_game():
		quit(2)
		return

	await scenario.run(self)

	if _aborted:
		return

	await frames(2)
	_report(opts)


func _report(opts: Dictionary) -> void:
	var total := passed + failed
	if failed == 0:
		print("TEST %-16s %d/%d ok" % [_scenario_id, passed, total])
	else:
		print("TEST %-16s %d/%d FAIL" % [_scenario_id, passed, total])

	# A scenario that never asked for a shot still gets one of its final state, so
	# -Mode shot always produces something to look at.
	if not _shot_dir.is_empty() and _shot_count == 0:
		await shot("final")

	await _drain_audio()
	quit(1 if failed > 0 else 0)


## The audio server only releases a stopped playback on its next mix tick. Quit
## in the same frame as a player is still going and that tick never comes, so
## Godot reports the playback as leaked at exit — an ERROR on stderr, which
## boot mode reads as a failure. Stop every player, then give the mixer a
## couple of frames to notice before quitting. Cosmetic in a real exit; not
## cosmetic for a check that greps stderr.
func _drain_audio() -> void:
	if root == null:
		return
	# Stop unconditionally: a one-shot that has finished reports playing=false
	# while its playback can still be awaiting the mixer's removal pass.
	for n in root.find_children("*", "AudioStreamPlayer", true, false):
		n.stop()
		n.stream = null
	await frames(6)


func _mount_game() -> bool:
	var packed: PackedScene = load(MAIN_SCENE_PATH)
	if packed == null:
		print("HARNESS FAIL  could not load %s" % MAIN_SCENE_PATH)
		return false
	game = packed.instantiate()
	if game == null:
		print("HARNESS FAIL  could not instantiate %s" % MAIN_SCENE_PATH)
		return false
	root.add_child(game)
	# Adding during _initialize does NOT run _ready immediately — the tree isn't
	# live until the first iteration, so @onready nodes are still null and
	# set_ai_features_enabled (which saves, and the save reads tasks_ui) would
	# throw. One frame is the earliest the network gate can be closed; nothing in
	# _ready reaches the provider, so that frame is not an exposure.
	await frames(1)
	game.set_ai_features_enabled(_ai_enabled)
	await frames(2)
	await settle()
	return true


## Read a --name=value passed through from check.ps1, e.g. -Node ep03_01.
func opt(name: String, default_value: String = "") -> String:
	return str(_opts.get(name, default_value))


# ---------------------------------------------------------------------------
# Driver API — what scenarios call
# ---------------------------------------------------------------------------

## Advance the game by `n` rendered frames.
func frames(n: int = 1) -> void:
	for _i in n:
		if _frames_used >= FRAME_BUDGET:
			_abort("frame budget exhausted (%d) — scenario is probably waiting on something that never happens" % FRAME_BUDGET)
			return
		_frames_used += 1
		await process_frame


## Fast-forward the typewriter and any remaining paragraph beats so the game is
## sitting on a settled line with its choices rendered. Every driver call below
## ends with this, so a scenario rarely needs to call it directly.
func settle(max_steps: int = 120) -> void:
	for _i in max_steps:
		await frames(1)
		if _aborted:
			return
		if game.dialogue_typewriter_active:
			game._finish_dialogue_typewriter()
			continue
		if game._has_more_beats():
			game._advance_to_next_beat()
			continue
		return


## Click on Yua herself.
func click_yua() -> void:
	game._on_character_clicked()
	await settle()


## Click the dialogue card / anywhere ("click to continue").
func click_card() -> void:
	game._on_subtitle_clicked()
	await settle()


## Current choice chip labels, in order, tokens substituted the same way the
## rendered buttons do it — so a label here reads as the player would see it.
func choices() -> Array:
	var out: Array = []
	for payload in game.current_choice_payloads:
		out.append(str(game._apply_text_tokens(str(payload.get("text", "")))))
	return out


## Pick a choice by index, or by a substring of its label. Returns false if no
## such choice is on screen.
func choose(which) -> bool:
	var payloads: Array = game.current_choice_payloads
	if payloads.is_empty():
		return false

	var index := -1
	if which is int:
		index = which
	else:
		var needle := str(which)
		for i in payloads.size():
			if str(payloads[i].get("text", "")).findn(needle) >= 0:
				index = i
				break

	if index < 0 or index >= payloads.size():
		return false

	game._on_choice_selected(payloads[index].duplicate(true))
	await settle()
	return true


## Type into the reply box and send it, the way Type Mode works for a player.
func type_reply(text: String) -> void:
	game._handle_player_text(text)
	await settle()


## Walk the conversation forward like a player who always takes the first option,
## until it settles on a node that goes nowhere. Returns the node id it stopped
## on. Nodes that want typed input (the Ep0 name prompt, task capture) get
## `typed_reply` once.
func play_forward(max_steps: int = 60, typed_reply: String = "小雨") -> String:
	for _i in max_steps:
		if _aborted:
			return node_id()
		var options := choices()
		if options.size() > 1:
			await choose(0)
			continue
		if options.size() == 1:
			await click_card()
			continue
		# Nothing on screen to click: either a terminal node, or one waiting on
		# typed input. Type once — if that moves nothing, this is the end.
		var before := node_id()
		await type_reply(typed_reply)
		if node_id() == before and choices().is_empty():
			return before
	return node_id()


## Start a focus session and drive it to completion. The clock is short-circuited
## rather than waited out — the completion path (`_update_focus_timer`) is the
## real one, so progression, saving and the episode beat all fire for real.
func complete_focus() -> void:
	game._on_start_focus_pressed()
	await frames(2)
	game.focus_time_left = -1.0
	for _i in 300:
		await frames(1)
		if _aborted or not game.focus_running:
			break
	await settle()


## Start a focus session and leave it running.
func start_focus() -> void:
	game._on_start_focus_pressed()
	await settle()


func set_focus_minutes(minutes: int) -> void:
	game._set_focus_duration_minutes(minutes)
	await frames(1)


# --- reading state ---------------------------------------------------------

func node_id() -> String:
	return str(game.current_node_id)


## The beat currently on screen. A multi-paragraph line is shown one beat at a
## time, so this is usually NOT the whole authored line — use full_line() to
## compare against source text.
func line() -> String:
	return str(game.dialogue_text.text)


## The whole authored line, beats rejoined, tokens already substituted.
func full_line() -> String:
	if game.dialogue_beats.is_empty():
		return str(game.dialogue_text.text)
	var parts: Array = []
	for beat in game.dialogue_beats:
		parts.append(str(beat))
	return "\n\n".join(parts)


func sessions() -> int:
	return int(game.completed_focus_sessions)


func focus_running() -> bool:
	return bool(game.focus_running)


func flags() -> Dictionary:
	if game.memory_manager != null and game.memory_manager.has_method("get_story_flags"):
		return game.memory_manager.call("get_story_flags")
	return {}


## True when the named node exists in scripted_nodes.json.
func has_node_id(id: String) -> bool:
	return game.scripted_dialogue_manager.has_dialogue_node(id)


# --- save handling ---------------------------------------------------------

## Delete the save file. check.ps1 backs up and restores the owner's real save
## around the whole run, so this never costs them progress.
func wipe_save() -> void:
	for path in SAVE_PATHS:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Tear the game down and boot it again from the save on disk. This is the only
## honest way to test "does X survive a restart" — the class of bug that keeps
## slipping through (episode flags that were never persisted).
func relaunch() -> void:
	game._save_persistent_state()
	await frames(1)
	game.queue_free()
	game = null
	await frames(3)
	await _mount_game()


# --- assertions ------------------------------------------------------------

## Record a check. On failure it also prints the game state, so a failing run
## explains itself without needing a second, more verbose run.
func check(label: String, ok: bool, detail: String = "") -> bool:
	if ok:
		passed += 1
		return true
	failed += 1
	if detail.is_empty():
		print("  x %s" % label)
	else:
		print("  x %s  — %s" % [label, detail])
	if game != null:
		print("    state: node=%s sessions=%d focus=%s choices=%s" % [
			node_id(), sessions(), str(focus_running()), str(choices()),
		])
		print("    line:  %s" % _one_line(line()))
	return false


func check_node(label: String, expected: String) -> bool:
	return check(label, node_id() == expected, "expected node '%s', got '%s'" % [expected, node_id()])


## The line currently on screen contains `needle`.
func check_line_has(label: String, needle: String) -> bool:
	return check(label, line().findn(needle) >= 0, "line does not contain '%s'" % needle)


func check_line_lacks(label: String, needle: String) -> bool:
	return check(label, line().findn(needle) < 0, "line should not contain '%s'" % needle)


# ---------------------------------------------------------------------------
# Screenshots (only when the run is windowed — headless renders nothing)
# ---------------------------------------------------------------------------

## Capture whatever is on screen right now. Call it from anywhere in a scenario,
## as often as you like — each call writes its own file:
##
##     await g.shot("before-timer")
##
## Silently no-ops in headless mode (there are no pixels to read), so a scenario
## can carry shot() calls permanently and only pay for them under -Mode shot.
func shot(label: String = "") -> void:
	if _shot_dir.is_empty():
		return
	_shot_count += 1
	var slug := label.strip_edges().replace(" ", "-")
	var file_name := "%s_%02d%s.png" % [_scenario_id, _shot_count, ("_" + slug) if slug != "" else ""]
	await capture_screenshot(_shot_dir.path_join(file_name))


func capture_screenshot(abs_path: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("  ! screenshot skipped — run with -Mode shot to capture pixels")
		return
	await frames(3)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("  ! screenshot failed — no viewport image")
		return
	var err := image.save_png(abs_path)
	if err != OK:
		print("  ! screenshot failed — save_png error %d" % err)
		return
	print("  shot: %s" % abs_path)


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _parse_user_args() -> Dictionary:
	var opts: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		var text := str(arg)
		if text.begins_with("--"):
			text = text.substr(2)
		if text.contains("="):
			var parts := text.split("=", true, 1)
			opts[parts[0]] = parts[1]
		elif not text.is_empty():
			opts[text] = true
	return opts


func _list_scenarios() -> void:
	var dir := DirAccess.open(SCENARIO_DIR)
	if dir == null:
		print("  (no scenarios directory)")
		return
	print("scenarios:")
	for file_name in dir.get_files():
		# Exported/packed projects rename .gd to .gdc; tolerate both.
		if not file_name.ends_with(".gd") and not file_name.ends_with(".gd.remap"):
			continue
		var id := file_name.trim_suffix(".remap").trim_suffix(".gd")
		var desc := ""
		var scenario_script = load(SCENARIO_DIR + id + ".gd")
		if scenario_script != null:
			var constants: Dictionary = scenario_script.get_script_constant_map()
			desc = str(constants.get("DESC", ""))
		print("  %-16s %s" % [id, desc])


func _start_watchdog(seconds: float) -> void:
	var watchdog := Timer.new()
	watchdog.wait_time = maxf(seconds, 5.0)
	watchdog.one_shot = true
	# autostart rather than start(): _initialize runs before the timer is inside
	# the tree, and Timer.start() refuses to run from there.
	watchdog.autostart = true
	watchdog.timeout.connect(func() -> void:
		_abort("timed out after %.0fs" % watchdog.wait_time)
	)
	root.add_child(watchdog)


func _abort(reason: String) -> void:
	if _aborted:
		return
	_aborted = true
	failed += 1
	print("TEST %-16s ABORT — %s" % [_scenario_id, reason])
	if game != null:
		print("    state: node=%s sessions=%d focus=%s" % [node_id(), sessions(), str(focus_running())])
	quit(3)


func _one_line(text: String) -> String:
	var flat := text.replace("\n", " / ").strip_edges()
	if flat.length() > 110:
		flat = flat.substr(0, 110) + "…"
	return flat
