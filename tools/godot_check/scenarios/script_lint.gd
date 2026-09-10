const DESC := "Not a test — dump every player-facing line and flag mechanical style/canon violations."
const NEEDS_GAME := false

## Mechanical half of a script audit. It cannot judge voice or setting (that is a
## reading job — see docs/Script_Audit_*.md), but it enforces every rule in
## docs/Chinese_Style_Guide.md and docs/Yua_Taste_Log.md that a regex can hold:
## 「……」 budget, dash/的 overuse, banned words, stage-direction parentheses,
## English in her mouth, dangling {name} punctuation, over-long beats.
##
##   check.ps1 -Mode test -Scenario script_lint > audit.txt
##
## Output: a full dump (one surface at a time) followed by the findings. All
## lines carry a four-space indent so check.ps1's filter passes them through.

const NODES_PATH := "res://data/dialogue/scripted_nodes.json"
const REACTIVE_PATH := "res://data/dialogue/reactive_lines.json"

# word -> why it is banned (taste log / style guide / AGENTS)
const BANNED := {
	"同桌": "taste log: 统一用「搭子」",
	"桑": "style guide: 称呼卖萌已禁（桑/酱/大人）",
	"大人": "style guide: 称呼卖萌已禁",
	"绝绝子": "style guide: 网络流行语",
	"yyds": "style guide: 网络流行语",
	"家人们": "style guide: 网络流行语",
	"加油": "persona: 不喊口号",
	"你真棒": "persona: 不喊口号",
	"一起努力": "persona: 不喊口号",
	"喜欢你": "persona: 不说喜欢/爱/想你",
	"爱你": "persona: 不说喜欢/爱/想你",
	"想你": "persona: 不说喜欢/爱/想你",
	"明天见": "taste log: 不引导「明天再来」",
	"明天再来": "taste log: 不引导「明天再来」",
	"明天你要是": "taste log: 不引导「明天再来」",
	"汇报": "taste log: 汇报/查岗框架（连否定式都不行）",
	"查岗": "taste log: 汇报/查岗框架",
	"话筒": "taste log: 游戏没有语音",
	"打卡": "AGENTS: 无打卡感",
	"任务完成": "AGENTS: 不做任务考核口吻",
	"我很乖": "taste log: 撒娇式自我形容",
	"封口费": "taste log: 保密/封口费梗作废",
	"目击": "taste log: 目击证人梗作废",
	"AI": "persona: never say she is an AI / no backend references",
	"模型": "persona: no model/backend references",
	"~": "style guide: 不用「~」卖萌",
}

var _dump: Array = []
var _findings: Array = []
var _counts: Dictionary = {}

func run(g) -> void:
	var root: Dictionary = _load_json(NODES_PATH)
	var reactive: Dictionary = _load_json(REACTIVE_PATH)
	if root.is_empty():
		g.check("scripted_nodes.json loads", false)
		return

	var nodes: Array = root.get("nodes", [])
	_say("=== SCRIPTED NODES (%d) ===" % nodes.size())
	for node in nodes:
		_audit_node(node)

	_say("")
	_say("=== REACTIVE POOLS ===")
	for category in reactive.keys():
		if str(category).begins_with("_"):
			continue
		var pool: Array = reactive[category]
		_say("-- %s (%d) --" % [category, pool.size()])
		for i in pool.size():
			var line := str(pool[i])
			_say("%s" % line)
			_lint_text("%s[%d]" % [category, i], line, false)

	_say("")
	_say("=== FINDINGS (%d) ===" % _findings.size())
	for f in _findings:
		_say("! " + str(f))
	_say("")
	_say("=== FINDING COUNTS BY RULE ===")
	var rules: Array = _counts.keys()
	rules.sort()
	for rule in rules:
		_say("%-28s %d" % [rule, _counts[rule]])

	g.check("script lint ran (%d findings)" % _findings.size(), true)


func _audit_node(node: Dictionary) -> void:
	var id := str(node.get("id", "?"))
	var line := str(node.get("line", ""))
	var tags: Array = node.get("tags", [])
	var flags = node.get("set_flags", [])
	var header := "@%s" % id
	if not tags.is_empty():
		header += "  tags=%s" % str(tags)
	if typeof(flags) == TYPE_ARRAY and not flags.is_empty():
		header += "  set=%s" % str(flags)
	elif typeof(flags) == TYPE_DICTIONARY and not flags.is_empty():
		header += "  set=%s" % str(flags.keys())
	_say(header)
	if line.strip_edges().is_empty():
		_say("  (blank line)")
		_flag("blank", id, "node has no line")
	else:
		for beat in line.split("\n"):
			var b := str(beat)
			if not b.strip_edges().is_empty():
				_say("  │ " + b)
		_lint_text(id, line, true)
	var choices: Array = node.get("choices", [])
	var labels: Array = []
	for c in choices:
		var text := str(c.get("text", ""))
		var next := str(c.get("next", ""))
		labels.append("[%s → %s]" % [text, next])
		_lint_choice(id, text)
	if not labels.is_empty():
		_say("  choices: " + "  ".join(PackedStringArray(labels)))


func _lint_text(id: String, text: String, is_node: bool) -> void:
	# --- whole-line checks
	var english := _english_prose(text)
	if not english.is_empty():
		_flag("english", id, "English prose in her line: «%s»" % english)
	for word in BANNED.keys():
		if text.find(str(word)) != -1:
			# "桑" and "AI" need guarding against false positives.
			if word == "桑" and not _regex_has(text, "[\\p{Han}]桑[，。！？…\\s]"):
				continue
			if word == "AI" and not _regex_has(text, "\\bAI\\b"):
				continue
			_flag("banned:" + str(word), id, "「%s」— %s" % [word, BANNED[word]])
	# 「酱」 as a name suffix (酱 in 酱油/果酱 is fine)
	if _regex_has(text, "[\\p{Han}A-Za-z]酱(?![油汁料])"):
		_flag("banned:酱", id, "「酱」称呼后缀 — style guide 已禁")
	var unknown_tokens := _regex_all(text, "\\{([a-z_]+)\\}")
	for t in unknown_tokens:
		if t != "name" and t != "focus_minutes":
			_flag("token:unknown", id, "unknown token {%s}" % t)
	if _regex_has(text, "\\{name\\}[。！？]") or _regex_has(text, "^\\{name\\}[。]"):
		_flag("token:name-punct", id, "{name} followed by 。/！/？ — leaves a dangling mark when the name is empty")
	# stage directions vs UI parentheticals
	for paren in _regex_all(text, "[（(]([^）)]{1,12})[）)]"):
		var p := str(paren)
		if _regex_has(p, "^(在下面|点击|输入|取好|选一个|按|回车)"):
			continue  # UI hint, allowed
		_flag("paren:stage-direction", id, "括号动作/语气「（%s）」— persona: 不输出括号动作" % p)

	# --- per-paragraph (beat) checks
	var beats := text.split("\n")
	for beat in beats:
		var b := str(beat).strip_edges()
		if b.is_empty():
			continue
		var ellipses := _count(b, "……")
		if ellipses > 1:
			_flag("ellipsis:>1/beat", id, "%d×「……」in one beat: «%s»" % [ellipses, _short(b)])
		if b.begins_with("……"):
			_flag("ellipsis:opens-beat", id, "beat opens with「……」: «%s»" % _short(b))
		if _count(b, "——") > 1:
			_flag("dash:>1/beat", id, "%d×「——」in one beat: «%s»" % [_count(b, "——"), _short(b)])
		if _count(b, "！") > 1:
			_flag("bang:>1/beat", id, "%d×「！」in one beat: «%s»" % [_count(b, "！"), _short(b)])
		var moe := _count(b, "嘿嘿") + _count(b, "呀") + _count(b, "啦")
		if moe > 1:
			_flag("moe:>1/beat", id, "%d× 嘿嘿/呀/啦 in one beat: «%s»" % [moe, _short(b)])
		var questions := _count(b, "？")
		if questions > 1:
			_flag("question:>1/beat", id, "%d 个问句 in one beat（问完给台阶，每段至多一问）: «%s»" % [questions, _short(b)])
		if is_node and b.length() > 60:
			_flag("beat:long", id, "beat is %d chars (一拍读不完): «%s»" % [b.length(), _short(b)])
		# sentences
		for sentence in _split_sentences(b):
			if _count(sentence, "的") >= 3:
				_flag("de:3+/sentence", id, "三个「的」: «%s»" % _short(sentence))
			if sentence.length() > 30:
				_flag("sentence:long", id, "%d-char sentence: «%s»" % [sentence.length(), _short(sentence)])


func _lint_choice(id: String, text: String) -> void:
	if text.strip_edges().is_empty():
		_flag("choice:blank", id, "blank choice label")
		return
	if _regex_has(text, "^(开始专注|汇报|打卡|完成任务|提交)"):
		_flag("choice:session-mgmt", id, "choice reads as session management: «%s»" % text)
	var english := _english_prose(text)
	if not english.is_empty():
		_flag("english", id, "English choice label: «%s»" % text)
	if text.length() > 14:
		_flag("choice:long", id, "%d-char chip: «%s»" % [text.length(), text])


# ---------------------------------------------------------------- helpers

func _flag(rule: String, id: String, detail: String) -> void:
	_findings.append("%s  %s  %s" % [rule.rpad(24), id, detail])
	_counts[rule] = int(_counts.get(rule, 0)) + 1

func _say(text: String) -> void:
	print("    " + text)

func _short(s: String) -> String:
	return s if s.length() <= 40 else s.substr(0, 40) + "…"

func _count(s: String, needle: String) -> int:
	return s.count(needle)

func _split_sentences(b: String) -> Array:
	var out: Array = []
	var regex := RegEx.new()
	regex.compile("[^。！？]+[。！？]?")
	for m in regex.search_all(b):
		var s := m.get_string().strip_edges()
		if not s.is_empty():
			out.append(s)
	return out

func _regex_has(s: String, pattern: String) -> bool:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return false
	return regex.search(s) != null

func _regex_all(s: String, pattern: String) -> Array:
	var out: Array = []
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return out
	for m in regex.search_all(s):
		out.append(m.get_string(1) if m.get_group_count() >= 1 else m.get_string())
	return out

# 3+ consecutive ASCII words = prose (tokens like "app" or "Yua" pass).
func _english_prose(text: String) -> String:
	var regex := RegEx.new()
	if regex.compile("[A-Za-z']+(\\s+[A-Za-z']+){2,}") != OK:
		return ""
	var m := regex.search(text)
	return "" if m == null else m.get_string()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
