const DESC := "At most two story episodes open per real day; focus stays unlimited; the counter survives a relaunch and resets on a new day."

## Owner + sister (2026-09-18): story is capped per day, focus is not. The
## harness lifts the cap by default; this scenario puts it back.

func run(g) -> void:
	g.game.daily_episode_cap = 2
	await g.click_yua()
	await g.play_forward()

	await g.complete_focus()
	g.check_node("first session → Ep1", "ep01_01")
	await g.play_forward()
	await g.complete_focus()
	g.check_node("second session → Ep2", "ep02_01")
	await g.play_forward()

	await g.complete_focus()
	g.check("third session of the day: no episode", not g.node_id().begins_with("ep0"), g.node_id())
	g.check("… but focus still completes and counts", g.sessions() == 3, str(g.sessions()))
	g.check("… and she still closes the session", g.node_id().begins_with("FOCUS_DONE"), g.node_id())
	g.check("Ep3 is not marked seen", not bool(g.flags().get("ep03_seen", false)))

	# The counter is persisted, so a relaunch the same day cannot dodge it.
	await g.relaunch()
	g.game.daily_episode_cap = 2
	await g.click_yua()
	await g.play_forward()
	await g.complete_focus()
	g.check("cap holds across a relaunch on the same day", not g.node_id().begins_with("ep0"), g.node_id())

	# A new day resets it.
	g.game._story_eps_today_key = "2000-01-01"
	g.game._story_eps_today = 2
	await g.play_forward()
	await g.complete_focus()
	g.check_node("a new day → Ep3 opens", "ep03_01")

	# 0 means unlimited (what the rest of the harness relies on).
	g.game.daily_episode_cap = 0
	await g.play_forward()
	await g.complete_focus()
	g.check_node("cap 0 → unlimited", "ep04_01")
