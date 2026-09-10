extends Node
# The "cute" layer of the journal UI (owner, 2026-09-10): the painted 9-slice
# cards are the structure; this adds the bits the mockup had on top of them — a
# strip of masking tape on the timer and tasks cards, a sticker-style "Yua" tag
# on the dialogue plate, a leaf sprig and a coffee-cup doodle.
#
# Everything is added in code, so the scene file stays untouched and removing
# this node restores the plain cards. Each piece loads from
# assets/art/ui/journal/ and is skipped if the file is missing.
#
# Pieces are NOT children of the panels: the panels are containers, and a
# container lays out its children to fill it (the first try produced a coffee
# cup the size of the timer card). Each piece is a sibling drawn right after
# its panel, pinned to the panel's rect and following its visibility.

const DIR := "res://assets/art/ui/journal/"

var _main: Node = null

func setup(main: Node) -> void:
	_main = main
	# Timer card: tape across the top-left corner, a coffee cup by the title,
	# a sprig tucked in the bottom-right corner.
	_attach("OverlayLayer/HUD/FocusCard", "tape.png", Vector2(-24, -20), 150, -6.0)
	_attach("OverlayLayer/HUD/FocusCard", "cup.png", Vector2(18, 44), 44, 0.0)
	_attach("OverlayLayer/HUD/FocusCard", "sprig.png", Vector2(-40, -36), 40, 14.0, true)
	# Tasks notebook: tape at the top.
	_attach("OverlayLayer/Tools/TasksPanel", "tape.png", Vector2(96, -18), 140, 4.0)
	# Music card: a small sprig in the bottom-left corner.
	_attach("BottomLeftMusicBar", "sprig.png", Vector2(6, -46), 40, -16.0, false, true)
	# Dialogue plate: the sticker tag replaces the plain "Yua" label.
	var tag := _attach("BottomPanel/DialoguePanel/DialogueCard", "tag_yua.png", Vector2(16, -24), 118, -3.0)
	if tag != null:
		var plain := _main.get_node_or_null("BottomPanel/DialoguePanel/DialogueCard/DialogueMargin/VBox/SpeakerTag")
		if plain is CanvasItem:
			(plain as CanvasItem).visible = false
	_attach("BottomPanel/DialoguePanel/DialogueCard", "sprig.png", Vector2(-54, -54), 48, 22.0, true)

# Place one piece over a panel. `offset` is measured from the panel's top-left
# corner, or from its bottom-right when `from_end` is set (bottom-left when
# `from_bottom_left`); `width` is the drawn width in px; `rot_deg` is the
# hand-placed tilt.
func _attach(panel_path: String, file: String, offset: Vector2, width: float, rot_deg: float, from_end: bool = false, from_bottom_left: bool = false) -> TextureRect:
	var panel := _main.get_node_or_null(panel_path)
	if not (panel is Control):
		return null
	var host := (panel as Control).get_parent()
	if host == null:
		return null
	var path := DIR + file
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var piece := TextureRect.new()
	piece.name = "Decor_%s_%s" % [(panel as Control).name, file.get_basename()]
	piece.texture = tex
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var h := width * float(tex.get_height()) / float(tex.get_width())
	piece.size = Vector2(width, h)
	piece.pivot_offset = piece.size / 2.0
	piece.rotation_degrees = rot_deg
	host.add_child(piece)
	host.move_child(piece, (panel as Control).get_index() + 1)
	var p := panel as Control
	var place := func():
		var base := p.position
		if from_end:
			base += p.size - piece.size
		elif from_bottom_left:
			base += Vector2(0, p.size.y - piece.size.y)
		piece.position = base + offset
		piece.visible = p.visible
	place.call()
	p.item_rect_changed.connect(place)
	p.visibility_changed.connect(place)
	return piece
