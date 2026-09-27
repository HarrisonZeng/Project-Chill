const DESC := "One sentence per click (quotes, 『novel』 paragraphs and （narration） stay whole), and 发送中: while her reply to a typed line is on its way nothing can skip past it."

## Owner, 2026-09-26: «make all lines come one sentence per click so each ep
## feels longer» and «after typing, show 发送中 during which players can't skip,
## so there's no bug».

const Service := preload("res://scripts/dialogue/ai_dialogue_service.gd")

# A provider that answers after `seconds` of real time — long enough to try
# every way of skipping while 发送中 is up. No network.
class SlowProvider extends Service.AiProvider:
	var tree: SceneTree
	var seconds: float
	var text: String
	func _init(t: SceneTree, s: float, reply: String) -> void:
		tree = t
		seconds = s
		text = reply
		provider_name = "stub"
	func is_available() -> bool:
		return true
	func generate_reply_async(_request: Dictionary) -> Dictionary:
		await tree.create_timer(seconds).timeout
		return {"text": text, "success": true, "provider": provider_name, "fallback_used": false}

func _split(g, text: String) -> Array:
	return g.game._split_into_beats(text)

func run(g) -> void:
	# --- The splitter.
	var cases := {
		"上啊上啊——打野呢？！打野人呢？！——哎别送啊——": ["上啊上啊——打野呢？！", "打野人呢？！", "——哎别送啊——"],
		"嗯？我在。": ["嗯？", "我在。"],
		"我刚刚在……学习。": ["我刚刚在……学习。"],
		"『汽笛响第四次的时候，镇上的灯会一起暗一下，像谁眨了眼。』": ["『汽笛响第四次的时候，镇上的灯会一起暗一下，像谁眨了眼。』"],
		"（她在忙自己的事。想说话，点一下她。）": ["（她在忙自己的事。想说话，点一下她。）"],
		"她原则是「我不问结果。只问你还在不在弄。」就这样。": ["她原则是「我不问结果。只问你还在不在弄。」就这样。"],
		"好了。\n\n你继续你的。": ["好了。", "你继续你的。"],
		"真的。……你按啊。": ["真的。", "……你按啊。"],
	}
	for src in cases:
		var got := _split(g, src)
		g.check("split: %s" % src.replace("\n", "/"), got == cases[src], str(got))

	# --- A real node: one sentence per click, choices only after the last.
	g.game._show_node("ep00_tools")
	await g.frames(1)
	var expected := _split(g, g.full_line()).size()
	g.check("ep00_tools has more sentences than paragraphs", expected > 2, str(expected))
	var clicks := 0
	var guard := 0
	while guard < 30:
		guard += 1
		if g.game.dialogue_typewriter_active:
			g.game._finish_dialogue_typewriter()
			await g.frames(1)
			continue
		if not g.game._has_more_beats():
			break
		g.check("no choices before the last sentence", not g.game.choice_list.visible)
		g.game._on_subtitle_clicked()
		clicks += 1
		await g.frames(1)
	g.check("one click per sentence", clicks == expected - 1, "%d clicks for %d sentences" % [clicks, expected])
	g.check("the last beat is the last sentence", g.line() == _split(g, g.full_line()).back(), g.line())
	g.check("choices show after the last sentence", g.game.choice_list.visible and g.choices().size() == 2, str(g.choices()))

	# --- 发送中. A 2 s stub reply on Ep3's 自己写 answer.
	var svc = g.game.ai_dialogue_service
	var real_provider = svc.provider
	svc.provider = SlowProvider.new(g.game.get_tree(), 2.0, "雨声好。我这边倒是不用放什么。")
	g.game.set_ai_features_enabled(true)
	g.game._show_node("ep03_01")
	await g.settle()
	await g.choose("我说说我的")
	await g.type_reply("我喜欢开着雨声")
	g.check("发送中 shows", g.game.status_label.visible and g.game.status_label.text.contains("发送中"), g.game.status_label.text)
	g.check("发送中: box is shut", not g.type_box_open())
	await g.shot("sending")
	var line_before: String = g.line()
	g.game._on_subtitle_clicked()
	g.game._on_character_clicked()
	g.game._handle_player_text("再发一句")
	g.game._on_start_focus_pressed()
	await g.frames(2)
	g.check("发送中: clicks on the card or on her do nothing", g.line() == line_before and g.node_id() == "ep03_01", "node=%s line=%s" % [g.node_id(), g.line()])
	g.check("发送中: the timer does not start", not g.focus_running())
	var t0 := Time.get_ticks_msec()
	while g.game._is_awaiting_reply() and Time.get_ticks_msec() - t0 < 5000:
		await g.game.get_tree().create_timer(0.05).timeout
	await g.settle()
	g.game.set_ai_features_enabled(false)
	svc.provider = real_provider
	g.check("reply lands on Ep3", g.full_line() == "雨声好。我这边倒是不用放什么。", g.full_line())
	g.check("发送中 is gone", not g.game.status_label.visible or not g.game.status_label.text.contains("发送中"), g.game.status_label.text)
	g.check("then 继续 into 你听", g.choices() == ["继续"], str(g.choices()))
	await g.click_card()
	g.check_node("继续 → the 你听 beat", "ep03_listen")

	# --- A hung request can't freeze the game: the lock lets go by itself.
	g.game._begin_awaiting_reply()
	g.game._awaiting_reply_since_ms = Time.get_ticks_msec() - g.game.AWAITING_REPLY_MAX_MS - 10
	await g.frames(2)
	g.check("a stuck 发送中 releases itself", not g.game._is_awaiting_reply())
