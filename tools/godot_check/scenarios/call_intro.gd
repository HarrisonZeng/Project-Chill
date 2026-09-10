const DESC := "The incoming-call opener: rings in Chinese, she answers by herself, skip() is instant."

## The overlay is the first thing any player (and any 小红书 video) sees. Since
## the owner's 2026-09-10 decision there is no button: the app launching IS the
## call, and Yua picks up after a short ring. The harness depends on skip()
## staying instant — if that breaks, every other scenario starts behind a modal.

func run(g) -> void:
	# The mounted game already had its overlay skipped by the harness.
	g.check("harness auto-answered the game's own overlay",
		g.game.get_node_or_null("CallIntro") == null)

	var scene: PackedScene = load("res://scenes/ui/call_intro.tscn")
	g.check("call_intro.tscn loads", scene != null)
	if scene == null:
		return

	# First-launch flavour.
	var intro: Control = scene.instantiate()
	g.game.add_child(intro)
	await g.frames(2)
	intro.setup(false, true)
	await g.frames(1)
	var status: Label = intro.get_node("Center/Col/StatusLabel")
	g.check("first launch rings in Chinese", status.text.begins_with("来电中"),
		"label was: %s" % status.text)
	var answer: Button = intro.get_node("Center/Col/AnswerRow/AnswerButton")
	g.check("no answer button is shown — she picks up herself", not answer.visible)

	# Ring (1.4 s) + connect (0.7 s) + fade (0.8 s) are wall-clock timers;
	# headless frames are not 1/60 s each, so poll rather than count frames.
	var connected := false
	var released := false
	for _i in 4000:
		await g.frames(1)
		if not is_instance_valid(intro) or intro.is_queued_for_deletion():
			released = true
			break
		if not connected and status.text.begins_with("连接中"):
			connected = true
		if intro.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			released = true
			break
	g.check("she moves to 连接中 on her own", connected or released)
	g.check("after connecting the overlay frees itself or stops blocking clicks", released)

	# Returning flavour + skip() stays instant.
	var intro2: Control = scene.instantiate()
	g.game.add_child(intro2)
	await g.frames(2)
	intro2.setup(true, false)
	await g.frames(1)
	var status2: Label = intro2.get_node("Center/Col/StatusLabel")
	g.check("returning player gets 重新连接", status2.text.begins_with("重新连接"),
		"label was: %s" % status2.text)
	intro2.skip()
	await g.frames(2)
	g.check("skip() removes the overlay immediately", not is_instance_valid(intro2) or intro2.is_queued_for_deletion())
