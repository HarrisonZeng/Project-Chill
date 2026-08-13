const DESC := "Script graph, episode metadata, reactive pools and scene files all load clean."

## Static validation, no playing. This is the cheap one to run after editing
## scripted_nodes.json — it catches a choice pointing at a node that does not
## exist, which in game just shows a transition-error card.

## Targets the engine handles itself rather than looking up in the node table.
## ACTION_* is handled by main_scene._handle_special_choice and AI_MODE_* flips
## Type Mode, so neither needs to exist as a node.
const SPECIAL_TARGETS := ["EXIT_DONE", "EXIT_NIGHT"]
const SPECIAL_PREFIXES := ["ACTION_", "AI_MODE_"]

func run(g) -> void:
	var manager = g.game.scripted_dialogue_manager
	var nodes: Dictionary = manager.nodes_by_id

	g.check("scripted_nodes.json loaded", nodes.size() > 0)
	g.check("intro node exists", g.has_node_id(str(g.game.intro_node_id)),
		"intro_node is '%s'" % str(g.game.intro_node_id))

	# Every choice target must resolve, or the player hits an error card.
	var dangling: Array = []
	for node_id in nodes:
		var node_data: Dictionary = nodes[node_id]
		for choice in node_data.get("choices", []):
			var target := str(choice.get("next", ""))
			if target.is_empty() or SPECIAL_TARGETS.has(target):
				continue
			var is_special := false
			for prefix in SPECIAL_PREFIXES:
				if target.begins_with(prefix):
					is_special = true
					break
			if is_special:
				continue
			if not manager.has_dialogue_node(target):
				dangling.append("%s -> %s" % [node_id, target])
	g.check("every choice points at a real node", dangling.is_empty(),
		"%d dangling: %s" % [dangling.size(), ", ".join(dangling.slice(0, 6))])

	# A node with no line AND no choices shows the player a blank card they cannot
	# leave. (A node with a line but no choices is fine — that is a terminal beat.)
	var empty_nodes: Array = []
	for node_id in nodes:
		var node_data: Dictionary = nodes[node_id]
		var spoken := str(node_data.get("line", node_data.get("text", "")))
		if spoken.strip_edges().is_empty() and node_data.get("choices", []).is_empty():
			empty_nodes.append(str(node_id))
	g.check("no node is blank and unleavable", empty_nodes.is_empty(),
		", ".join(empty_nodes.slice(0, 6)))

	# Episode metadata drives progression; a bad start_node silently stalls the story.
	var bad_episodes: Array = []
	var seen_gates: Dictionary = {}
	for episode in g.game.episode_metadata:
		var start_node := str(episode.get("start_node", ""))
		var gate := int(episode.get("session_gate", -1))
		if not manager.has_dialogue_node(start_node):
			bad_episodes.append("%s start_node '%s' missing" % [str(episode.get("id", "?")), start_node])
		if gate < 0:
			bad_episodes.append("%s has no session_gate" % str(episode.get("id", "?")))
		elif seen_gates.has(gate):
			bad_episodes.append("gate %d used twice (%s, %s)" % [gate, seen_gates[gate], str(episode.get("id", "?"))])
		else:
			seen_gates[gate] = str(episode.get("id", "?"))
	g.check("episode metadata is sound", bad_episodes.is_empty(),
		", ".join(bad_episodes.slice(0, 6)))

	# An episode whose seen_flag is never set replays forever.
	var unflagged: Array = []
	for episode in g.game.episode_metadata:
		var seen_flag := str(episode.get("seen_flag", ""))
		if seen_flag.is_empty():
			continue
		var start_node := str(episode.get("start_node", ""))
		if not manager.has_dialogue_node(start_node):
			continue
		if not manager.get_dialogue_node(start_node).get("set_flags", {}).has(seen_flag):
			unflagged.append("%s does not set %s" % [start_node, seen_flag])
	g.check("each episode sets its own seen_flag", unflagged.is_empty(),
		", ".join(unflagged.slice(0, 6)))

	# Reactive pools are picked from at runtime; an empty one means silence.
	for pool_name in ["idle_click", "idle_click_prefocus", "focus_click"]:
		g.check("reactive pool '%s' has lines" % pool_name,
			g.game._reactive_pool(pool_name).size() > 0)

	# Every scene in the project still opens — catches a node renamed out from
	# under an @onready path.
	var broken_scenes: Array = []
	for scene_path in _all_scenes("res://scenes"):
		var packed = load(scene_path)
		if packed == null:
			broken_scenes.append(scene_path)
			continue
		var instance = packed.instantiate()
		if instance == null:
			broken_scenes.append(scene_path)
		else:
			instance.free()
	g.check("all scenes load and instantiate", broken_scenes.is_empty(),
		", ".join(broken_scenes.slice(0, 4)))


func _all_scenes(dir_path: String) -> Array:
	var found: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file_name in dir.get_files():
		if file_name.ends_with(".tscn"):
			found.append(dir_path.path_join(file_name))
	for sub_dir in dir.get_directories():
		found.append_array(_all_scenes(dir_path.path_join(sub_dir)))
	return found
