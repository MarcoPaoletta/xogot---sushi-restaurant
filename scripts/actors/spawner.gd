extends Node
## Builds the day's fixed order schedule and asks the restaurant to spawn customers (GDD section 11).

signal spawn_requested(orders: Array, seat_index: int)

var schedule: Array = []      # Array of Array[String] (each customer's dish ids)
var spawned := 0
var seats_free: Array[bool] = []
var gap := 6.0
var running := false
var _cooldown := 0.0

const MODELS := [
	"Rabbit_Bald", "Rabbit_Blond", "Rabbit_Cyan", "Rabbit_Green", "Rabbit_Grey", "Rabbit_Pink", "Rabbit_Purple",
]


func build(day: Dictionary, day_index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + day_index
	var dishes: Array = day["dishes"]
	var double_every: int = day.get("double_every", 0)
	schedule.clear()
	var last := ["", ""]
	for i in int(day["customers"]):
		var orders: Array = []
		var count := 2 if double_every > 0 and (i + 1) % double_every == 0 else 1
		for k in count:
			var pick: String = dishes[rng.randi() % dishes.size()]
			var tries := 0
			while pick == last[0] and pick == last[1] and tries < 8:
				pick = dishes[rng.randi() % dishes.size()]
				tries += 1
			orders.append(pick)
			last = [pick, last[0]]
		schedule.append(orders)
	seats_free.clear()
	for s in int(day["seats"]):
		seats_free.append(true)
	gap = float(day["gap"])
	spawned = 0
	_cooldown = 1.2


func start() -> void:
	running = true


func stop() -> void:
	running = false


func remaining() -> int:
	return schedule.size() - spawned


func free_seat(index: int) -> void:
	if index >= 0 and index < seats_free.size():
		seats_free[index] = true


func model_for(index: int) -> String:
	return MODELS[index % MODELS.size()]


func _process(delta: float) -> void:
	if not running or spawned >= schedule.size():
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var seat := seats_free.find(true)
	if seat == -1:
		return
	seats_free[seat] = false
	spawn_requested.emit(schedule[spawned], seat)
	spawned += 1
	_cooldown = gap
