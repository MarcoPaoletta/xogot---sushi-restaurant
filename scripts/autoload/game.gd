extends Node
## Global game state: the five-day schedule, save data, scene switching, results hand-off.

signal day_started(index: int)
signal day_finished(result: Dictionary)

const SAVE_PATH := "user://save.json"

## GDD section 11.
const DAYS: Array[Dictionary] = [
	{"name": "Opening", "customers": 8, "seats": 2, "dishes": ["salmon_nigiri", "maguro_nigiri", "onigiri"],
		"stations": ["rice", "nori", "salmon", "tuna"], "patience": 30.0, "gap": 6.0, "target": 60, "double_every": 0},
	{"name": "Regulars", "customers": 10, "seats": 3, "dishes": ["salmon_nigiri", "maguro_nigiri", "onigiri", "ebi_nigiri", "cucumber_roll"],
		"stations": ["rice", "nori", "salmon", "tuna", "ebi", "cucumber"], "patience": 26.0, "gap": 5.0, "target": 100, "double_every": 0},
	{"name": "Lunch rush", "customers": 12, "seats": 4, "dishes": ["salmon_nigiri", "maguro_nigiri", "onigiri", "ebi_nigiri", "cucumber_roll", "tamago_nigiri", "salmon_roll"],
		"stations": ["rice", "nori", "salmon", "tuna", "ebi", "cucumber", "egg"], "patience": 26.0, "gap": 4.5, "target": 150, "double_every": 4},
	{"name": "Festival", "customers": 14, "seats": 4, "dishes": ["salmon_nigiri", "maguro_nigiri", "onigiri", "ebi_nigiri", "cucumber_roll", "tamago_nigiri", "salmon_roll", "octopus_nigiri", "urchin_roll"],
		"stations": ["rice", "nori", "salmon", "tuna", "ebi", "cucumber", "egg", "tentacle", "urchin"], "patience": 24.0, "gap": 4.0, "target": 210, "double_every": 4},
	{"name": "Grand finale", "customers": 16, "seats": 4, "dishes": ["salmon_nigiri", "maguro_nigiri", "onigiri", "ebi_nigiri", "cucumber_roll", "tamago_nigiri", "salmon_roll", "octopus_nigiri", "urchin_roll"],
		"stations": ["rice", "nori", "salmon", "tuna", "ebi", "cucumber", "egg", "tentacle", "urchin"], "patience": 22.0, "gap": 3.5, "target": 280, "double_every": 4},
]

var current_day := 0
var last_result: Dictionary = {}
var save_data: Dictionary = {"days": {}, "music": true, "sfx": true, "tutorial_done": false}
var main: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save()


# --- navigation -------------------------------------------------------------

func go_to_menu() -> void:
	_switch("res://scenes/ui/main_menu.tscn")


func go_to_days() -> void:
	_switch("res://scenes/ui/day_select.tscn")


func start_day(index: int) -> void:
	current_day = clampi(index, 0, DAYS.size() - 1)
	_switch("res://scenes/restaurant.tscn")
	day_started.emit(current_day)


func restart_day() -> void:
	start_day(current_day)


func next_day() -> void:
	if current_day + 1 < DAYS.size():
		start_day(current_day + 1)
	else:
		_switch("res://scenes/ui/ending.tscn")


func day_complete(result: Dictionary) -> void:
	last_result = result
	var key := str(current_day)
	var entry: Dictionary = save_data["days"].get(key, {})
	if result.get("completed", false):
		entry["completed"] = true
		entry["stars"] = maxi(int(entry.get("stars", 0)), int(result.get("stars", 0)))
		if current_day == 0:
			save_data["tutorial_done"] = true
	entry["best_earnings"] = maxi(int(entry.get("best_earnings", 0)), int(result.get("earnings", 0)))
	entry["best_streak"] = maxi(int(entry.get("best_streak", 0)), int(result.get("best_streak", 0)))
	save_data["days"][key] = entry
	write_save()
	day_finished.emit(result)
	_switch("res://scenes/ui/results.tscn")


func _switch(path: String) -> void:
	if main and main.has_method("switch_to"):
		main.switch_to(path)
	else:
		get_tree().change_scene_to_file(path)


# --- queries ----------------------------------------------------------------

func day_entry(index: int) -> Dictionary:
	return save_data["days"].get(str(index), {})


func is_unlocked(index: int) -> bool:
	return index == 0 or day_entry(index - 1).get("completed", false)


func total_stars() -> int:
	var n := 0
	for k in save_data["days"]:
		n += int(save_data["days"][k].get("stars", 0))
	return n


func best_day_earnings() -> int:
	var n := 0
	for k in save_data["days"]:
		n = maxi(n, int(save_data["days"][k].get("best_earnings", 0)))
	return n


func total_earnings() -> int:
	var n := 0
	for k in save_data["days"]:
		n += int(save_data["days"][k].get("best_earnings", 0))
	return n


func tutorial_done() -> bool:
	return save_data.get("tutorial_done", false)


# --- persistence ------------------------------------------------------------

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed:
			save_data[k] = parsed[k]


func write_save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_data))


func set_music_enabled(on: bool) -> void:
	save_data["music"] = on
	Audio.set_music_enabled(on)
	write_save()


func set_sfx_enabled(on: bool) -> void:
	save_data["sfx"] = on
	Audio.set_sfx_enabled(on)
	write_save()


func format_time(t: float) -> String:
	@warning_ignore("integer_division")
	var m := int(t) / 60
	var s := int(t) % 60
	return "%d:%02d" % [m, s]
