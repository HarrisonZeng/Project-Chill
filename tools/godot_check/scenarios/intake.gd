const DESC := "Launch questionnaire: steps and copy, answers land on the profile, Ep0 reacts to the profile name, returning players never see it."

## The overlay is skipped in headless runs, so this drives the component
## directly (the same way call_intro.gd does) and then checks the hand-off into
## main_scene: nickname/role saved, Ep0's name beat reads the profile instead
## of asking, and a relaunch does not need the questionnaire again.

func run(g) -> void:
	var scene: PackedScene = load("res://scenes/ui/intake.tscn")
	g.check("intake.tscn loads", scene != null)
	if scene == null:
		return

	# --- Steps and copy (owner 2026-09-23: no 搭子 / 合拍 anywhere).
	var intake: Control = scene.instantiate()
	g.game.add_child(intake)
	await g.frames(2)
	intake.call("start")
	await g.frames(1)
	g.check("first step is the welcome", intake.call("current_step") == "welcome")
	var prompt: Label = intake.get_node("Center/Col/Prompt")
	g.check("welcome copy", prompt.text == "先回答几个问题。", prompt.text)
	intake.call("_on_continue")
	await g.frames(1)
	g.check("second step asks the nickname", intake.call("current_step") == "nickname")
	g.check("nickname copy", prompt.text == "你的昵称是", prompt.text)
	var input: LineEdit = intake.get_node("Center/Col/Input")
	input.text = "小林"
	intake.call("_on_continue")
	await g.frames(1)
	g.check("third step asks the role", intake.call("current_step") == "role")
	g.check("role copy", prompt.text == "你是来——", prompt.text)
	var labels: Array = []
	for b in intake.get_node("Center/Col/Buttons").get_children():
		labels.append((b as Button).text)
	g.check("role buttons are 一起学习 / 一起工作 / 其他", labels == ["一起学习", "一起工作", "其他"], str(labels))
	intake.call("_pick_role", "study")
	await g.frames(1)
	g.check("then it is matching", intake.call("current_step") == "matching")
	var all_text := ""
	for n in intake.find_children("*", "Label", true, false):
		all_text += (n as Label).text
	g.check("no 搭子 / 合拍 in the questionnaire copy", not all_text.contains("搭子") and not all_text.contains("合拍"), all_text)
	intake.queue_free()
	await g.frames(2)

	# --- Hand-off into the game (the path the real overlay takes).
	g.wipe_save()
	await g.relaunch()
	var intake2: Control = scene.instantiate()
	g.game.add_child(intake2)
	await g.frames(2)
	intake2.finished.connect(g.game._on_intake_finished)
	intake2.call("skip_with", "小林", "study", "")
	await g.frames(3)
	g.check("nickname saved on the game", g.game.player_nickname == "小林", g.game.player_nickname)
	g.check("role saved on the game", g.game.player_role == "study", g.game.player_role)
	g.check("intake marked done", g.game.intake_done)
	var packet: String = g.game._build_context_packet("AI_MODE_BREAK_CHAT")
	g.check("AI context packet carries the role", packet.contains("player_role=student"), packet)

	# Ep0 now reacts to the profile name instead of asking for it.
	await g.click_yua()
	var guard := 0
	while g.node_id() != "ep00_react" and guard < 20:
		await g.click_card()
		guard += 1
	g.check_node("Ep0 reaches the profile-name beat", "ep00_react")
	g.check("she says she looked at the profile", g.full_line().contains("资料"), g.full_line())
	await g.click_card()
	await g.settle()
	g.check("reaction node shows (no asking)", g.node_id() == "ep00_name_react", g.node_id())
	g.check("reaction mentions the name or 本名", g.line().contains("小林") or g.line().contains("本名"), g.line())
	await g.click_card()
	g.check_node("继续 → ep00_named with the name", "ep00_named")
	g.check("ep00_named substitutes {name}", g.full_line().contains("小林"), g.full_line())

	# Survives a relaunch; a blank nickname still falls back to asking.
	await g.relaunch()
	g.check("intake_done survives a relaunch", g.game.intake_done)
	g.check("nickname survives a relaunch", g.game.player_nickname == "小林", g.game.player_nickname)

	# relaunch() saves the live state before rebooting, so clear it in memory
	# too — otherwise the wiped file is simply written back.
	g.game.player_nickname = ""
	g.game.intake_done = false
	g.game.has_seen_intro = false
	g.game.memory_manager.set_story_flag("intro_seen", false)
	g.game.memory_manager.set_player_nickname("")
	g.wipe_save()
	await g.relaunch()
	await g.click_yua()
	guard = 0
	while g.node_id() != "ep00_react" and guard < 20:
		await g.click_card()
		guard += 1
	await g.click_card()
	await g.settle()
	g.check_node("blank nickname → the asking node", "ep00_name")
	g.check("asking copy mentions the empty profile", g.full_line().contains("没写名字"), g.full_line())
