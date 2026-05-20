class_name CallStatusController
extends PanelContainer

# Owns the call-status pill (OverlayLayer/HUD/CallStatusPill): the connection
# status line, the date/detail line, and the colored status dot.
# main_scene calls refresh(language, is_focusing) whenever those inputs change
# (every frame, on language switch, and on startup). All strings resolve through
# the UiStrings autoload so this component is self-contained.

@onready var status_dot: Panel = $Col/Row1/StatusDot
@onready var status_line: Label = $Col/Row1/StatusLine
@onready var detail_line: Label = $Col/DetailLine

func refresh(language: String, is_focusing: bool) -> void:
	if status_line == null:
		return
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var time_str: String = "%02d:%02d" % [now.hour, now.minute]
	var date_str: String = "%04d/%02d/%02d" % [now.year, now.month, now.day]
	var weekday_str: String = UiStrings.t("weekday.%d" % int(now.weekday), language)
	var bucket_str: String = _bucket_label(int(now.hour), language)
	var speaker: String = UiStrings.t("call.speaker", language)
	var status_key: String = "call.status.focusing" if is_focusing else "call.status.connected"
	var status_word: String = UiStrings.t(status_key, language)
	status_line.text = "%s · %s · %s" % [speaker, status_word, time_str]
	if detail_line != null:
		detail_line.text = "%s · %s · %s" % [date_str, weekday_str, bucket_str]
	_refresh_dot(is_focusing)

func _refresh_dot(is_focusing: bool) -> void:
	if status_dot == null:
		return
	var sb := status_dot.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	sb.bg_color = get_theme_color("honey_amber", "Palette") if is_focusing else get_theme_color("sage", "Palette")

func _bucket_label(hour: int, language: String) -> String:
	if hour >= 5 and hour < 12:
		return UiStrings.t("time.morning", language)
	if hour >= 12 and hour < 17:
		return UiStrings.t("time.afternoon", language)
	if hour >= 17 and hour < 22:
		return UiStrings.t("time.evening", language)
	return UiStrings.t("time.night", language)
