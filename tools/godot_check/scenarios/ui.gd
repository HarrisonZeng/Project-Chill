const DESC := "Screenshot the UI panels and collapsed states: -Mode shot -Scenario ui"

## For looking at chrome rather than story. Opens the panels that are hidden by
## default and captures the collapse states, so changes to Settings, the music
## bar and the dialogue box can be checked without clicking through the game.
##
##   check.ps1 -Mode shot -Scenario ui

func run(g) -> void:
	var game = g.game

	# Settings, opened. This is the panel that gains the window-view and stance
	# rows, and the one most likely to overflow its own box.
	var panel = game.get_node_or_null("SettingsPanel")
	if panel != null:
		panel.visible = true
		await g.settle()
		await g.shot("settings-open")
		g.check("settings panel fits its content", _fits(panel),
			"content is taller than the panel")
		panel.visible = false

	var view = game.get("view_options")
	if view == null:
		g.check("view options present", false, "ViewOptions node missing")
		return
	g.check("view options present", true)

	# Everything collapsed: what the player sees when they just want the scene.
	view._on_chrome_collapse()
	await g.settle()
	await g.shot("chrome-collapsed")
	var music = game.get_node_or_null("BottomLeftMusicBar")
	var dialogue = game.get_node_or_null("BottomPanel/DialoguePanel")
	g.check("music bar hidden when collapsed", music != null and not music.visible)
	g.check("dialogue hidden when collapsed", dialogue != null and not dialogue.visible)

	# And restored — a collapse with no way back would be a trap.
	view._on_chrome_collapse()
	await g.settle()
	g.check("music bar returns", music != null and music.visible)
	g.check("dialogue returns", dialogue != null and dialogue.visible)
	await g.shot("chrome-restored")

## True when the panel is at least as tall as the content it holds.
func _fits(panel) -> bool:
	var box = panel.get_node_or_null("SettingsMargin/SettingsVBox")
	if box == null:
		return false
	return panel.size.y + 1.0 >= box.get_combined_minimum_size().y
