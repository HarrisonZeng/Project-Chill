class_name CalendarController
extends Control

# The paper calendar card on the left (owner, 2026-09-24). Owns the calendar
# toggle button beside the settings gear and the card under it: a month grid
# drawn in the journal style — today ringed in honey, days you focused together
# stamped in soft sage, festivals and her own dates marked with a small dot
# (hover a day to read it).
#
# Deliberately NOT a streak tracker: no counts, no "missed" days, nothing that
# reads as 打卡. A blank day is just a day. Data comes from main_scene through
# set_data(); visibility is persisted by main_scene via save_requested.

signal save_requested

const CELL_H := 30.0
const HEAD_H := 22.0

# Fixed-date festivals (month-day) and pre-computed lunar ones (full date).
# Lunar dates match data/dialogue/greeting_pools.json; extend past 2028 there
# and here together.
const FIXED_MARKS := {
	"01-01": {"zh": "元旦", "en": "New Year's Day"},
	"02-14": {"zh": "情人节", "en": "Valentine's Day"},
	"05-01": {"zh": "劳动节", "en": "Labour Day"},
	"10-01": {"zh": "国庆", "en": "National Day"},
	"12-24": {"zh": "平安夜", "en": "Christmas Eve"},
	"12-25": {"zh": "圣诞", "en": "Christmas"},
	"12-31": {"zh": "跨年", "en": "New Year's Eve"},
}
const LUNAR_MARKS := {
	"2026-02-17": {"zh": "春节", "en": "Spring Festival"},
	"2027-02-06": {"zh": "春节", "en": "Spring Festival"},
	"2028-01-26": {"zh": "春节", "en": "Spring Festival"},
	"2026-09-25": {"zh": "中秋", "en": "Mid-Autumn"},
	"2027-09-15": {"zh": "中秋", "en": "Mid-Autumn"},
	"2028-10-03": {"zh": "中秋", "en": "Mid-Autumn"},
}
const MONTHS_EN := ["January", "February", "March", "April", "May", "June", "July",
	"August", "September", "October", "November", "December"]
const WEEKDAY_ZH := ["日", "一", "二", "三", "四", "五", "六"]
const WEEKDAY_EN := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

const ICON_CALENDAR: Texture2D = preload("res://assets/art/ui/icons/calendar.svg")

@onready var calendar_button: Button = $CalendarButton
@onready var card: PanelContainer = $CalendarCard
@onready var month_label: Button = $CalendarCard/Col/Header/MonthLabel
@onready var prev_button: Button = $CalendarCard/Col/Header/PrevButton
@onready var next_button: Button = $CalendarCard/Col/Header/NextButton
@onready var grid: Control = $CalendarCard/Col/Grid
@onready var footer: Label = $CalendarCard/Col/Footer

var language: String = "zh"
var card_visible: bool = true
# "YYYY-MM-DD" -> minutes focused together that day (0 = the 3-sec test chip).
var focus_days: Dictionary = {}
var first_focus_key: String = ""
var story_flags: Dictionary = {}
var view_year: int = 0
var view_month: int = 0
var _today_key_cached: String = ""
var _hover_cell: int = -1

func _ready() -> void:
	var now := Time.get_date_dict_from_system()
	view_year = int(now.year)
	view_month = int(now.month)
	_today_key_cached = _today_key()
	if calendar_button != null:
		calendar_button.icon = ICON_CALENDAR
		calendar_button.pressed.connect(_on_button_pressed)
	if prev_button != null:
		prev_button.pressed.connect(_shift_month.bind(-1))
	if next_button != null:
		next_button.pressed.connect(_shift_month.bind(1))
	if month_label != null:
		month_label.pressed.connect(_back_to_today)
	if grid != null:
		grid.draw.connect(_draw_grid)
		grid.gui_input.connect(_on_grid_input)
		grid.mouse_exited.connect(func(): _hover_cell = -1; grid.queue_redraw())
	# The date can roll over while the call sits open all night.
	var tick := Timer.new()
	tick.wait_time = 60.0
	tick.autostart = true
	tick.timeout.connect(_on_minute_tick)
	add_child(tick)
	refresh()

# --- public API used by main_scene ---

func apply_language(lang: String) -> void:
	language = lang
	refresh()

func set_data(days: Dictionary, first_key: String, flags: Dictionary) -> void:
	focus_days = days.duplicate()
	first_focus_key = first_key
	story_flags = flags.duplicate()
	refresh()

func is_card_visible() -> bool:
	return card_visible

func set_card_visible(on: bool) -> void:
	card_visible = on
	refresh()

func refresh() -> void:
	if card != null:
		card.visible = card_visible
	if calendar_button != null:
		calendar_button.tooltip_text = UiStrings.t("calendar.tooltip", language)
	if prev_button != null:
		prev_button.tooltip_text = UiStrings.t("calendar.prev", language)
	if next_button != null:
		next_button.tooltip_text = UiStrings.t("calendar.next", language)
	if month_label != null:
		month_label.text = _month_title(view_year, view_month)
		month_label.tooltip_text = UiStrings.t("calendar.back_today", language)
	if grid != null:
		grid.custom_minimum_size = Vector2(0, HEAD_H + CELL_H * _rows_needed(view_year, view_month))
		grid.queue_redraw()
	if footer != null:
		footer.text = _footer_text()

# What a given day carries, for tooltips and tests: {focus, minutes, marks[]}.
func day_info(key: String) -> Dictionary:
	var marks: Array = []
	var md := key.substr(5)
	if LUNAR_MARKS.has(key):
		marks.append(_local(LUNAR_MARKS[key]))
	if FIXED_MARKS.has(md):
		marks.append(_local(FIXED_MARKS[md]))
	if key == first_focus_key and not first_focus_key.is_empty():
		marks.append(UiStrings.t("calendar.first_day", language))
	# Her rent day, once the story has told you about her money (Ep9: the
	# 店长 cuts her hours) — the same 房租 her notebook carries on the 1st.
	if md.ends_with("-01") and bool(story_flags.get("ep09_seen", false)):
		marks.append(UiStrings.t("calendar.rent", language))
	var info := {"focus": focus_days.has(key), "minutes": int(focus_days.get(key, 0)), "marks": marks}
	return info

# --- internals ---

func _on_button_pressed() -> void:
	card_visible = not card_visible
	if card_visible:
		_back_to_today()
	refresh()
	save_requested.emit()

func _shift_month(delta: int) -> void:
	view_month += delta
	while view_month < 1:
		view_month += 12
		view_year -= 1
	while view_month > 12:
		view_month -= 12
		view_year += 1
	refresh()

func _back_to_today() -> void:
	var now := Time.get_date_dict_from_system()
	view_year = int(now.year)
	view_month = int(now.month)
	refresh()

func _on_minute_tick() -> void:
	var key := _today_key()
	if key != _today_key_cached:
		_today_key_cached = key
		_back_to_today()

func _today_key() -> String:
	var now := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(now.year), int(now.month), int(now.day)]

func _local(entry: Dictionary) -> String:
	return str(entry.get(language, entry.get("en", "")))

func _month_title(y: int, m: int) -> String:
	if language == "zh":
		return UiStrings.t("calendar.month", language) % [y, m]
	return UiStrings.t("calendar.month", language) % [MONTHS_EN[m - 1], y]

static func _days_in_month(y: int, m: int) -> int:
	if m == 2:
		var leap := (y % 4 == 0 and y % 100 != 0) or y % 400 == 0
		return 29 if leap else 28
	return 30 if m in [4, 6, 9, 11] else 31

# Monday-first column (0..6) of the 1st of the month.
static func _first_column(y: int, m: int) -> int:
	var unix := Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": 1, "hour": 12, "minute": 0, "second": 0})
	var wd := int(Time.get_datetime_dict_from_unix_time(unix).weekday)  # 0 = Sunday
	return (wd + 6) % 7

func _rows_needed(y: int, m: int) -> int:
	return int(ceil(float(_first_column(y, m) + _days_in_month(y, m)) / 7.0))

func _footer_text() -> String:
	var now := Time.get_date_dict_from_system()
	var today := _today_key()
	var tomorrow_unix := Time.get_unix_time_from_datetime_dict({"year": now.year, "month": now.month, "day": now.day, "hour": 12}) + 86400
	var t := Time.get_datetime_dict_from_unix_time(tomorrow_unix)
	var tomorrow := "%04d-%02d-%02d" % [int(t.year), int(t.month), int(t.day)]
	var today_fest := _festival(today)
	if not today_fest.is_empty():
		return UiStrings.t("calendar.today_is", language) % today_fest
	var tomorrow_fest := _festival(tomorrow)
	if not tomorrow_fest.is_empty():
		return UiStrings.t("calendar.tomorrow_is", language) % tomorrow_fest
	var wd := int(Time.get_datetime_dict_from_system().weekday)
	if language == "zh":
		return UiStrings.t("calendar.today_line", language) % [int(now.month), int(now.day), WEEKDAY_ZH[wd]]
	return UiStrings.t("calendar.today_line", language) % [MONTHS_EN[int(now.month) - 1], int(now.day), WEEKDAY_EN[wd]]

func _festival(key: String) -> String:
	if LUNAR_MARKS.has(key):
		return _local(LUNAR_MARKS[key])
	var md := key.substr(5)
	if FIXED_MARKS.has(md):
		return _local(FIXED_MARKS[md])
	return ""

func _cell_at(pos: Vector2) -> int:
	if grid == null or pos.y < HEAD_H:
		return -1
	var col := int(pos.x / (grid.size.x / 7.0))
	var row := int((pos.y - HEAD_H) / CELL_H)
	var day := row * 7 + col - _first_column(view_year, view_month) + 1
	if col < 0 or col > 6 or day < 1 or day > _days_in_month(view_year, view_month):
		return -1
	return day

func _on_grid_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		return
	var day := _cell_at((event as InputEventMouseMotion).position)
	if day == _hover_cell:
		return
	_hover_cell = day
	grid.tooltip_text = _tooltip_for(day)
	grid.queue_redraw()

func _tooltip_for(day: int) -> String:
	if day < 1:
		return ""
	var info := day_info("%04d-%02d-%02d" % [view_year, view_month, day])
	var lines: Array = []
	for m in info.marks:
		lines.append(str(m))
	if bool(info.focus):
		var minutes := int(info.minutes)
		lines.append(UiStrings.t("calendar.focus_day", language) % minutes if minutes > 0 else UiStrings.t("calendar.focus_day_short", language))
	return "\n".join(lines)

func _draw_grid() -> void:
	var font := get_theme_default_font()
	var ink := get_theme_color("espresso_brown", "Palette")
	var soft := get_theme_color("ink_soft", "Palette")
	var honey := get_theme_color("honey_amber", "Palette")
	var sage := get_theme_color("sage", "Palette")
	var brick := get_theme_color("brick_warm", "Palette")
	var w := grid.size.x / 7.0

	# Weekday initials; the weekend in a warmer ink.
	var names := UiStrings.t("calendar.weekdays", language).split(",")
	for c in 7:
		var col_ink := brick if c >= 5 else soft
		col_ink.a = 0.8
		var label := names[c] if c < names.size() else ""
		grid.draw_string(font, Vector2(c * w, HEAD_H - 7), label, HORIZONTAL_ALIGNMENT_CENTER, w, 12, col_ink)

	var today := _today_key()
	var first_col := _first_column(view_year, view_month)
	for day in range(1, _days_in_month(view_year, view_month) + 1):
		var idx := first_col + day - 1
		var cx := (idx % 7) * w + w / 2.0
		var cy := HEAD_H + floorf(idx / 7.0) * CELL_H + CELL_H / 2.0
		var key := "%04d-%02d-%02d" % [view_year, view_month, day]
		var info := day_info(key)
		var r := minf(w, CELL_H) * 0.42
		if day == _hover_cell:
			grid.draw_circle(Vector2(cx, cy), r, Color(sage, 0.18))
		# A day you focused together: a soft sage stamp behind the number.
		if bool(info.focus):
			grid.draw_circle(Vector2(cx, cy), r, Color(sage, 0.55))
		# Today: a hand-drawn honey ring (two slightly offset strokes).
		if key == today:
			grid.draw_arc(Vector2(cx, cy), r + 1.5, -2.9, 3.0, 28, honey, 2.0, true)
			grid.draw_arc(Vector2(cx + 0.8, cy - 0.6), r + 2.3, 2.6, 3.5, 8, honey, 1.6, true)
		var num_ink := ink if key <= today else Color(ink, 0.55)
		grid.draw_string(font, Vector2(cx - w / 2.0, cy + 5), str(day), HORIZONTAL_ALIGNMENT_CENTER, w, 14, num_ink)
		if not (info.marks as Array).is_empty():
			grid.draw_circle(Vector2(cx + r * 0.78, cy - r * 0.78), 2.6, brick)
