const DESC := "Photograph every window view through the real window: -Mode shot -Scenario views"

## A painted view is easy to judge as a flat file and easy to get wrong in
## place, because the window only reveals a band across its middle. This walks
## every available view and captures it as the player actually sees it.
##
##   check.ps1 -Mode shot -Scenario views

func run(g) -> void:
	var game = g.game
	var view = game.get("view_options")
	if view == null:
		g.check("view options present", false, "ViewOptions node missing")
		return

	var keys = view.available_views()
	g.check("at least one view has art", keys.size() > 0)

	for key in keys:
		# Drive the same path the Settings button uses, so this exercises the
		# real swap rather than poking the texture directly.
		game._on_weather_picked(key)
		await g.settle()
		await g.shot("view-" + str(key))
		var bg = game.get_node_or_null("Background")
		g.check("%s has a texture" % key, bg != null and bg.texture != null)

	# Leave the scene on the view it started with rather than the last one
	# walked, so running this does not silently change the owner's save.
	game._on_weather_picked(view.get_weather())
