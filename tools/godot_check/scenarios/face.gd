const DESC := "Photograph Yua neutral, mid-blink, and smiling: -Mode shot -Scenario face"

## Blink lasts a quarter of a second, so a random still never catches it. This
## triggers each face state on purpose and photographs it, which is the only
## way to check the overlays actually land on the portrait rather than beside
## it. Run in shot mode; headless it just checks the plumbing exists.

func run(g) -> void:
	var game = g.game
	var face = game.get("companion_face")
	g.check("companion face present", face != null)
	if face == null:
		return

	await g.settle()
	await g.shot("neutral")

	face.blink_now()
	await g.frames(4)   # ~65 ms in: lids should be down
	await g.shot("mid-blink")
	await g.frames(20)

	face.show_expression("smile", 3.0)
	await g.frames(24)  # past the 0.25 s fade-in
	await g.shot("smile")

	# Overlays must sit exactly on the portrait.
	var portrait = game.get_node_or_null("CompanionStage/CompanionView/Portrait")
	var blink = game.get_node_or_null("CompanionStage/CompanionView/BlinkLayer")
	g.check("blink layer exists", blink != null)
	if portrait != null and blink != null:
		g.check("blink layer matches portrait rect",
			blink.get_global_rect() == portrait.get_global_rect(),
			"blink %s vs portrait %s" % [blink.get_global_rect(), portrait.get_global_rect()])
	# The hands overlay lives above the desk, outside CompanionView, so its rect
	# is synced by hand — that is the one that can drift.
	var hands = game.get_node_or_null("HandsLayer")
	if hands != null and portrait != null:
		g.check("hands layer matches portrait rect",
			hands.get_global_rect() == portrait.get_global_rect(),
			"hands %s vs portrait %s" % [hands.get_global_rect(), portrait.get_global_rect()])
		g.check("hands layer stretch matches portrait",
			hands.expand_mode == portrait.expand_mode and hands.stretch_mode == portrait.stretch_mode)
		# With the desk hidden, the overlay must coincide with her real arms —
		# photograph it so a mismatch is visible, not just numeric.
		var desk = game.get_node_or_null("DeskFront")
		if desk != null:
			desk.visible = false
			await g.frames(2)
			await g.shot("hands-over-arms-no-desk")
			desk.visible = true

	# Every frame the Settings flip-through offers must exist in both stances —
	# a missing file is skipped silently in play, so only this catches it.
	# Expressions are photographed at full strength; poses swap the base.
	var expressions := ["smile", "shy", "surprised", "thinking", "rest", "focus", "sleepy",
		"giggle", "wink", "pout", "delighted", "window"]
	var frames_needed: Array = expressions + ["blink", "hands", "typing_b", "hands_b",
		"drink", "drink_hands", "chin", "chin_hands"]
	var first_stance = game.get("yua_stance")
	for stance in ["at_player", "at_work"]:
		game._on_stance_picked(stance)
		await g.frames(2)
		var missing: Array = []
		for f in frames_needed:
			if face._variant_for(f) == null:
				missing.append(f)
		g.check("%s stance has every frame" % stance, missing.is_empty(), "missing: %s" % [missing])
	game._on_stance_picked("at_player")
	await g.frames(2)

	# A pose redraws her arms; blink and expression frames are arms-down
	# drawings, so any of them showing over a pose puts a phantom pair of arms
	# on screen. A pose must clear them and hold them off until it ends.
	var expr_layer = game.get_node_or_null("CompanionStage/CompanionView/ExpressionLayer")
	face.show_expression("smile", 5.0)
	await g.frames(24)
	face.show_pose("drink", 1.0)
	face.blink_now()
	face.show_expression("wink", 2.0)
	await g.frames(12)
	g.check("pose clears and holds off face overlays",
		expr_layer != null and expr_layer.modulate.a == 0.0 and blink.modulate.a == 0.0,
		"expression %.2f blink %.2f" % [expr_layer.modulate.a if expr_layer else -1.0, blink.modulate.a])
	await g.frames(90)

	if g.shooting():
		for e in expressions:
			face.show_expression(e, 2.0)
			await g.frames(24)
			await g.shot("expr-" + e)
			await g.frames(60)
		for p in ["drink", "chin"]:
			while face._pose_active:
				await g.frames(1)
			face.show_pose(p, 1.0)
			await g.frames(3)
			await g.shot("pose-" + p)
		while face._pose_active:
			await g.frames(1)
		# Typing only runs while focus does — main_scene drives set_working
		# from focus_running every frame.
		game.focus_running = true
		await g.frames(1)
		face._on_type_timer()
		await g.frames(2)
		await g.shot("typing-b")
		game.focus_running = false
		await g.frames(1)
	game._on_stance_picked(first_stance)
	await g.frames(2)

	# The other stance is a different pose with its own hands cut. Switch to it
	# the way Settings does, photograph it, and confirm a hands texture is set
	# — a missing one would leave her hands under the desk.
	var start_stance = game.get("yua_stance")
	game._on_stance_picked("at_work")
	await g.frames(3)
	await g.shot("at-work-stance")
	if hands != null:
		g.check("at_work stance has its own hands texture", hands.texture != null)
	game._on_stance_picked(start_stance)
