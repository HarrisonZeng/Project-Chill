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
