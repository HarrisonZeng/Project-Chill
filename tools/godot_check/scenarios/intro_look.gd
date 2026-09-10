const DESC := "Photograph the self-answering call intro at its ring and connect moments: -Mode shot -Scenario intro_look"

## The game's own overlay is skipped by the harness; this mounts a fresh one on
## top of the running scene and shoots it while it rings and while it connects,
## so the opener can be reviewed without launching the app by hand.

func run(g) -> void:
	var scene: PackedScene = load("res://scenes/ui/call_intro.tscn")
	g.check("call_intro.tscn loads", scene != null)
	if scene == null:
		return
	var intro: Control = scene.instantiate()
	g.game.add_child(intro)
	await g.frames(2)
	intro.setup(false, true)
	await g.frames(2)
	await g.shot("intro-ringing")

	var status: Label = intro.get_node("Center/Col/StatusLabel")
	# Poll wall-clock: ring (1.4 s) then 连接中 (0.7 s) then fade.
	for _i in 3000:
		await g.frames(1)
		if not is_instance_valid(intro):
			break
		if status.text.begins_with("连接中"):
			await g.shot("intro-connecting")
			break
	for _i in 3000:
		await g.frames(1)
		if not is_instance_valid(intro) or intro.is_queued_for_deletion() or intro.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			break
	g.check("intro released on its own", not is_instance_valid(intro) or intro.is_queued_for_deletion() or intro.mouse_filter == Control.MOUSE_FILTER_IGNORE)
