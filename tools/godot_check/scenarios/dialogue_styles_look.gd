const DESC := "Photograph the dialogue box in three looks for the owner to pick: -Mode shot -Scenario dialogue_styles_look (A stitched card = current; B her notebook page; C call subtitle). Runtime-only overrides, nothing in the game changes."

## Owner 2026-09-24: "make the edges align with the other boxes … actually do
## you think there should be another option? might be a bit repetitive".

const TAPE := preload("res://assets/art/ui/journal/tape.png")

func run(g) -> void:
	g.game._show_node("ep05_01")
	await g.settle()
	var card: PanelContainer = g.game.dialogue_card
	var text: RichTextLabel = g.game.dialogue_text
	await g.shot("A-stitched-card")

	# B — a page from her notebook: ruled lines, a red margin rule, square-ish
	# corners with a soft shadow, held on by two strips of tape.
	var page := StyleBoxFlat.new()
	page.bg_color = Color(0.992, 0.973, 0.925, 0.98)
	page.set_corner_radius_all(3)
	page.shadow_color = Color(0.24, 0.16, 0.14, 0.28)
	page.shadow_size = 8
	page.shadow_offset = Vector2(0, 3)
	page.content_margin_left = 40
	page.content_margin_right = 24
	page.content_margin_top = 18
	page.content_margin_bottom = 12
	card.theme_type_variation = &""
	card.add_theme_stylebox_override("panel", page)
	var rules := func():
		var blue := Color(0.55, 0.68, 0.80, 0.35)
		var y := 44.0
		while y < card.size.y - 6:
			card.draw_line(Vector2(10, y), Vector2(card.size.x - 10, y), blue, 1.0)
			y += 30.0
		card.draw_line(Vector2(30, 4), Vector2(30, card.size.y - 4), Color(0.85, 0.45, 0.42, 0.55), 1.2)
	card.draw.connect(rules)
	var tapes: Array = []
	for spec in [[Vector2(card.size.x - 70, -14), 26.0], [Vector2(card.size.x * 0.5 - 45, card.size.y - 18), -4.0]]:
		var t := TextureRect.new()
		t.texture = TAPE
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		t.size = Vector2(90, 33)
		t.pivot_offset = t.size / 2.0
		t.rotation_degrees = spec[1]
		t.position = card.position + spec[0]
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.get_parent().add_child(t)
		tapes.append(t)
	card.queue_redraw()
	await g.frames(3)
	await g.shot("B-notebook-page")
	card.draw.disconnect(rules)
	for t in tapes:
		t.queue_free()

	# C — a video-call subtitle: translucent plum glass, no border, cream text.
	# The journal cards stay for the tools; her voice reads as "the call".
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(0.168627, 0.133333, 0.188235, 0.66)
	glass.set_corner_radius_all(16)
	glass.content_margin_left = 24
	glass.content_margin_right = 24
	glass.content_margin_top = 16
	glass.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", glass)
	text.add_theme_color_override("default_color", Color(0.984, 0.957, 0.894, 1.0))
	card.queue_redraw()
	await g.frames(3)
	await g.shot("C-call-subtitle")
	g.check("three looks captured", true)
