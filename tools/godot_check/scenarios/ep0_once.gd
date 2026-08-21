const DESC := "Ep0 never replays once it has been seen — including across a relaunch and after a debug jump."

## first_click.gd already covers repeat clicks inside one click-initiated session.
## This covers the two paths it cannot see, both of which put the player back at
## ep00_01 after they had already finished the intro:
##
##   Cause B: `has_seen_intro` (a save field) and the `intro_seen` story flag are
##            two sources of truth. `_apply_node_flags` writes the flag and saves
##            the profile while `has_seen_intro` is still false, so a save can end
##            up saying "intro seen" and "intro not seen" at the same time.
##   Cause A: the debug jumper sets has_seen_intro = false and shows a node without
##            spending `_conversation_opened_this_session`, so the next Yua click
##            re-resolves an opener and restarts the intro mid-session.

func run(g) -> void:
	# --- Cause B: a profile that knows the intro was seen must never replay it.
	g.wipe_save()
	await g.click_yua()
	g.check_node("a fresh save opens the intro", "ep00_01")

	# Reproduce the split-brain save exactly as _apply_node_flags can leave it:
	# the story flag is set (and persisted), the boolean is not.
	g.game.memory_manager.set_story_flag("intro_seen", true)
	g.game.has_seen_intro = false
	g.game._save_persistent_state()

	await g.relaunch()
	await g.click_yua()
	g.check("a profile with intro_seen set does not replay Ep0",
		g.node_id() != "ep00_01",
		"landed back on %s" % g.node_id())

	# --- Cause A: debug-jumping to Ep0, playing it, then clicking her must not
	# restart it inside the same session.
	g.wipe_save()
	await g.relaunch()
	g.game._debug_timeline_jump("ep00_01", 0)
	await g.settle()
	g.check_node("debug jump lands on the intro", "ep00_01")

	await g.click_yua()
	g.check("clicking her after a debug jump does not restart Ep0",
		g.node_id() != "ep00_01",
		"landed back on %s" % g.node_id())
