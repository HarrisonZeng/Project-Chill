class_name UiStrings
extends RefCounted

# Minimal i18n string map for Project Chill UI.
# New widgets added in the UI redesign use UiStrings.t(key, lang).
# Existing main_scene.gd._ui_text() is migrated incrementally as widgets are rebuilt.

const STRINGS := {
	"call.speaker": {"zh": "Yua", "en": "Yua"},
	"call.status.connected": {"zh": "已连接", "en": "Connected"},
	"call.status.focusing": {"zh": "专注中", "en": "Focusing"},
	"call.status.break": {"zh": "休息中", "en": "Break"},
	"weekday.0": {"zh": "周日", "en": "Sun"},
	"weekday.1": {"zh": "周一", "en": "Mon"},
	"weekday.2": {"zh": "周二", "en": "Tue"},
	"weekday.3": {"zh": "周三", "en": "Wed"},
	"weekday.4": {"zh": "周四", "en": "Thu"},
	"weekday.5": {"zh": "周五", "en": "Fri"},
	"weekday.6": {"zh": "周六", "en": "Sat"},
	"time.morning": {"zh": "早晨", "en": "Morning"},
	"time.afternoon": {"zh": "下午", "en": "Afternoon"},
	"time.evening": {"zh": "傍晚", "en": "Evening"},
	"time.night": {"zh": "夜晚", "en": "Night"},
	"focus.title.idle": {"zh": "专注计时", "en": "Focus Timer"},
	"focus.title.running": {"zh": "专注中", "en": "Focusing"},
	"focus.custom": {"zh": "自定", "en": "Custom"},
	"focus.custom.placeholder": {"zh": "分钟", "en": "Minutes"},
	"focus.custom.apply": {"zh": "确定", "en": "Apply"},
	"focus.task": {"zh": "任务", "en": "Task"},
	"focus.icon.start": {"zh": "▶", "en": "▶"},
	"focus.icon.stop": {"zh": "◼", "en": "◼"},
	"tasks.title": {"zh": "任务", "en": "Tasks"},
	"tasks.empty": {"zh": "还没添加任务 · 在下方输入开始", "en": "No tasks yet · type below to add"},
	"tasks.new_placeholder": {"zh": "新任务 · 回车添加", "en": "New task · press Enter"},
	"tasks.task_placeholder": {"zh": "任务", "en": "Task"},
	"tasks.delete": {"zh": "删除", "en": "Delete"},
	"tasks.mark_done": {"zh": "标记完成", "en": "Mark done"},
	"tasks.close": {"zh": "关闭", "en": "Close"},
	"tasks.counter": {"zh": "· %d 项 · %d 已完成 ·", "en": "· %d items · %d done ·"},
	"tasks.counter_empty": {"zh": "· 还没有任务 ·", "en": "· no tasks ·"},
	"tasks.tab.label": {"zh": "任务", "en": "Tasks"},
	"tasks.resize.tooltip": {"zh": "拖动调整任务面板大小", "en": "Drag to resize tasks panel"},
	"music.no_track": {"zh": "未加载音乐", "en": "No track loaded"},
	"music.song_prefix": {"zh": "歌曲：", "en": "Song: "},
	"music.play": {"zh": "播放", "en": "Play"},
	"music.pause": {"zh": "暂停", "en": "Pause"},
	"music.mode.loop": {"zh": "循环", "en": "Loop"},
	"music.mode.seq": {"zh": "顺序", "en": "Seq"},
	"music.mode.random": {"zh": "随机", "en": "Random"},
	"voice.on": {"zh": "语音开", "en": "Voice On"},
	"voice.off": {"zh": "语音关", "en": "Voice Off"},
}

static func t(key: String, lang: String = "en") -> String:
	if not STRINGS.has(key):
		return key
	var entry: Dictionary = STRINGS[key]
	if entry.has(lang):
		return String(entry[lang])
	return String(entry.get("en", key))
