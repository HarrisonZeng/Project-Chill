const DESC := "Typing at a (自己写) choice: reply, no chips, no UI-speak, chat continues."

## Covers Progress.md "User Godot Checks Pending" #4.
##
## Runs with AI disabled, which is the honest case to test: it is the path a
## player hits whenever the provider is unreachable or switched off, and it must
## still sound like Yua rather than like a manual.

const META_WORDING := ["按钮", "buttons", "button", "回到", "settings", "Type Mode"]

func run(g) -> void:
	# ABORT_REST is the shortest route to a 自己写 choice; jump straight there.
	g.game._show_node("ABORT_REST")
	await g.settle()
	g.check("reached a node with a 自己写 choice", g.choices().size() > 1,
		"choices were %s" % str(g.choices()))

	var picked: bool = await g.choose("说会儿话")
	g.check("the 自己写 choice can be taken", picked)

	await g.type_reply("有点累，不太想动")

	g.check("her reply is not blank", not g.full_line().strip_edges().is_empty())
	g.check("no chips after a typed reply", g.choices().is_empty(),
		"chips still on screen: %s" % str(g.choices()))

	var leaked: Array = []
	for phrase in META_WORDING:
		if g.full_line().findn(phrase) >= 0:
			leaked.append(phrase)
	g.check("her reply contains no UI-speak", leaked.is_empty(),
		"leaked %s in: %s" % [str(leaked), g.full_line()])

	# Typing again should just continue the conversation.
	await g.type_reply("嗯，那再坐一会儿")
	g.check("typing again continues the chat", not g.full_line().strip_edges().is_empty())
	g.check("still no chips on the second reply", g.choices().is_empty())

	# And clicking her settles back into co-presence rather than dead-ending.
	await g.click_yua()
	g.check("clicking her after typing still responds", not g.full_line().strip_edges().is_empty())
