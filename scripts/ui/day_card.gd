extends Button
## One day card: number, name, stars, best earnings (or a lock).

@onready var day_label: Label = $Layout/DayLabel
@onready var name_label: Label = $Layout/NameLabel
@onready var stars: HBoxContainer = $Layout/Stars
@onready var best: Label = $Layout/Best
@onready var lock: Control = $Layout/LockBox/Lock


func setup(index: int) -> void:
	var info: Dictionary = Game.DAYS[index]
	var entry := Game.day_entry(index)
	var unlocked := Game.is_unlocked(index)
	UiKit.style_button(self, (UiKit.WOOD if unlocked else Color(0.4, 0.35, 0.33)), 30)
	custom_minimum_size = Vector2(300, 380)
	text = ""
	disabled = not unlocked
	UiKit.style_label(day_label, 44)
	UiKit.style_label(name_label, 30, Color(1, 0.95, 0.85), 6)
	UiKit.style_label(best, 26, Color(1, 1, 1, 0.9), 5)
	day_label.text = "Day %d" % (index + 1)
	name_label.text = info["name"]
	var got := int(entry.get("stars", 0))
	var i := 0
	for s in stars.get_children():
		s.on = i < got
		s.visible = unlocked
		i += 1
	lock.visible = not unlocked
	if unlocked:
		best.text = ("Best %d" % int(entry["best_earnings"])) if entry.has("best_earnings") else "Target %d" % int(info["target"])
		pressed.connect(func(): Game.start_day(index))
	else:
		best.text = "Finish day %d" % index
