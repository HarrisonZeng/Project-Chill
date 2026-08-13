const DESC := "Every .gd compiles and every JSON data file parses. Does not boot the game."

## NEEDS_GAME = false so this still runs when main_scene is too broken to load —
## which is exactly when you want to know which file has the syntax error.
const NEEDS_GAME := false

const SCRIPT_DIRS := ["res://scripts", "res://tools/godot_check"]
const JSON_DIRS := ["res://data"]

## Force-recompiling a script that is currently executing crashes the engine, so
## the harness and this file are checked by the fact that they are running at all.
const SELF_EXCLUDE := [
	"res://tools/godot_check/harness.gd",
	"res://tools/godot_check/scenarios/lint.gd",
]

func run(g) -> void:
	var broken_scripts: Array = []
	var script_count := 0
	for dir_path in SCRIPT_DIRS:
		for path in _files_under(dir_path, ".gd"):
			if SELF_EXCLUDE.has(path):
				continue
			script_count += 1
			# CACHE_MODE_IGNORE forces a real recompile; a cached hit would let a
			# freshly broken file pass. A script that failed to parse comes back
			# null or unable to instantiate.
			var script := ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
			if script == null or not (script as Script).can_instantiate():
				broken_scripts.append(path.replace("res://", ""))
	g.check("%d GDScript files compile" % script_count, broken_scripts.is_empty(),
		", ".join(broken_scripts.slice(0, 6)))

	var broken_json: Array = []
	var json_count := 0
	for dir_path in JSON_DIRS:
		for path in _files_under(dir_path, ".json"):
			json_count += 1
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				broken_json.append("%s (unreadable)" % path.replace("res://", ""))
				continue
			var parser := JSON.new()
			if parser.parse(file.get_as_text()) != OK:
				broken_json.append("%s line %d: %s" % [
					path.replace("res://", ""), parser.get_error_line(), parser.get_error_message(),
				])
	g.check("%d JSON files parse" % json_count, broken_json.is_empty(),
		", ".join(broken_json.slice(0, 4)))


func _files_under(dir_path: String, suffix: String) -> Array:
	var found: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file_name in dir.get_files():
		if file_name.ends_with(suffix):
			found.append(dir_path.path_join(file_name))
	for sub_dir in dir.get_directories():
		found.append_array(_files_under(dir_path.path_join(sub_dir), suffix))
	return found
