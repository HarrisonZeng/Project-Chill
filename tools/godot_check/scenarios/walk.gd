const DESC := "Not a test — play the game and print the conversation as text. -Node/-Sessions to jump, -Pick to steer."

## The token-light playtest: no window, no screenshots — just what she says and
## what the player could tap, as plain text. ~1s per run.
##
##   check.ps1 -Mode test -Scenario walk                    # fresh save, first click, auto-play
##   check.ps1 -Mode test -Scenario walk -Node ep03_01 -Sessions 3
##   check.ps1 -Mode test -Scenario walk -Pick "2,1,t:超级霸王龙,1"
##
## -Pick is a comma list consumed in order: a number taps that choice (1-based),
## "t:某句话" types it into the input box. When the list runs out the walk
## auto-plays: first choice if there is one, otherwise a click on Yua. A started
## focus session is completed automatically so episode beats keep flowing.
## Every transcript line is indented four spaces — that is what lets it through
## check.ps1's output filter untouched.

func run(g) -> void:
	var node_id: String = g.opt("node")
	var sessions: int = int(g.opt("sessions", "0"))
	var picks: Array = []
	for p in str(g.opt("pick", "")).split(","):
		var token := str(p).strip_edges()
		if not token.is_empty():
			picks.append(token)

	if not node_id.is_empty():
		if not g.has_node_id(node_id):
			g.check("node '%s' exists" % node_id, false, "not found in scripted_nodes.json")
			return
		g.game._debug_timeline_jump(node_id, sessions)
		await g.settle()
		_say("· jumped to %s (sessions=%d)" % [node_id, sessions])
	else:
		_say("· fresh save · click on Yua")
		await g.click_yua()

	_print_state(g)

	for step in 30:
		var acted := false

		if not picks.is_empty():
			var token: String = picks.pop_front()
			if token.begins_with("t:"):
				var typed := token.substr(2)
				_say("→ type: %s" % typed)
				await g.type_reply(typed)
				acted = true
			else:
				var index := int(token) - 1
				var labels: Array = g.choices()
				if index >= 0 and index < labels.size():
					_say("→ pick %d: %s" % [index + 1, labels[index]])
					await g.choose(index)
					acted = true
				else:
					_say("! pick '%s' out of range (%d choices) — auto-playing instead" % [token, labels.size()])

		if not acted:
			var labels: Array = g.choices()
			if not labels.is_empty():
				_say("→ pick 1: %s" % labels[0])
				await g.choose(0)
			else:
				var before_node: String = g.node_id()
				var before_line: String = g.full_line()
				_say("→ click")
				await g.click_yua()
				if g.node_id() == before_node and g.full_line() == before_line and g.choices().is_empty():
					_say("· settled — nothing new, stopping")
					break

		if g.focus_running():
			_say("· focus session started → completing it")
			await g.complete_focus()

		_print_state(g)

		# Out of scripted picks and back at co-presence idle: one more click would
		# only draw another pool line, so the walk is over.
		if picks.is_empty() and g.choices().is_empty() and g.node_id() == "idle":
			break

	g.check("walk completed", true)


func _print_state(g) -> void:
	var line: String = g.full_line()
	if line.strip_edges().is_empty():
		_say("YUA @%s: (blank)" % g.node_id())
	else:
		_say("YUA @%s:" % g.node_id())
		for beat in line.split("\n"):
			if not str(beat).strip_edges().is_empty():
				_say("│ %s" % str(beat))
	var labels: Array = g.choices()
	if not labels.is_empty():
		var parts: Array = []
		for i in labels.size():
			parts.append("[%d] %s" % [i + 1, labels[i]])
		_say("· choices: %s" % "  ".join(PackedStringArray(parts)))


## Four leading spaces = survives check.ps1's non-Raw output filter.
func _say(text: String) -> void:
	print("    " + text)
