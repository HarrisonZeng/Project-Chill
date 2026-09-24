const DESC := "Photograph the launch questionnaire step by step: -Mode shot -Scenario intake_look"

## Windowed only (headless renders nothing). Drives the overlay through its
## steps and takes a picture of each, so the copy and layout can be checked
## without a hand on the mouse.

func run(g) -> void:
	var scene: PackedScene = load("res://scenes/ui/intake.tscn")
	if scene == null:
		g.check("intake.tscn loads", false)
		return
	var intake: Control = scene.instantiate()
	g.game.add_child(intake)
	intake.z_index = 900
	await g.frames(2)
	intake.call("start")
	await g.frames(3)
	await g.shot("intake-1-welcome")
	intake.call("_on_continue")
	await g.frames(3)
	var input: LineEdit = intake.get_node("Center/Col/Input")
	input.text = "小林"
	await g.shot("intake-2-nickname")
	intake.call("_on_continue")
	await g.frames(3)
	await g.shot("intake-3-role")
	intake.call("_on_role_other")
	await g.frames(3)
	input.text = "写毕业论文"
	await g.shot("intake-3b-role-other")
	intake.call("_on_continue")
	await g.frames(20)
	await g.shot("intake-4-matching")
	# wait out the matching timer
	await g.frames(160)
	await g.shot("intake-5-matched")
	var still_alive := is_instance_valid(intake) and not intake.is_queued_for_deletion()
	g.check("walked every step", (not still_alive) or str(intake.call("current_step")) in ["matching", "matched", ""],
		str(intake.call("current_step")) if still_alive else "overlay already freed")
