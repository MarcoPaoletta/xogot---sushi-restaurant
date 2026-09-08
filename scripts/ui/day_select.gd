extends Control
## Five day cards in a row.

const CARD := preload("res://scenes/ui/day_card.tscn")

@onready var cards: HBoxContainer = $Cards
@onready var title: Label = $Title
@onready var back: Button = $Back


func _ready() -> void:
	UiKit.style_title(title, 80)
	UiKit.style_button(back, Color(0.45, 0.4, 0.5), 32)
	back.custom_minimum_size = Vector2(200, 80)
	back.pressed.connect(func(): Game.go_to_menu())
	Audio.play_music("menu")
	for i in Game.DAYS.size():
		var card := CARD.instantiate()
		cards.add_child(card)
		card.setup(i)
		UiKit.fly_in(card, 0.06 * i)
