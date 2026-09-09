class_name Recipes
## Static data: ingredients, stations and dish recipes (GDD section 6.2).

const KIT := "res://assets/Sushi Restaurant Kit - May 2023/"
const UFP := "res://assets/Ultimate Food Pack - Oct 2019/FBX/"

## Ingredient id -> display name and the model shown on its station.
const INGREDIENTS := {
	"rice": {"name": "Rice", "model": KIT + "Food/glTF/FoodIngredient_Rice.gltf", "scale": 0.9},
	"nori": {"name": "Nori", "model": KIT + "Food/glTF/FoodIngredient_Nori.gltf", "scale": 0.9},
	"salmon": {"name": "Salmon", "model": KIT + "Food/glTF/FoodIngredient_Salmon.gltf", "scale": 1.0},
	"tuna": {"name": "Tuna", "model": KIT + "Food/glTF/FoodIngredient_Tuna.gltf", "scale": 0.8},
	"ebi": {"name": "Ebi", "model": KIT + "Food/glTF/FoodIngredient_Ebi.gltf", "scale": 1.6},
	"egg": {"name": "Tamago", "model": UFP + "Egg_Fried.fbx", "scale": 0.9},
	"tentacle": {"name": "Octopus", "model": KIT + "Food/glTF/FoodIngredient_Tentacle.gltf", "scale": 1.0},
	"cucumber": {"name": "Cucumber", "model": KIT + "Food/glTF/FoodIngredient_SlicedCucumber.gltf", "scale": 1.0},
	"urchin": {"name": "Urchin", "model": KIT + "Food/glTF/FoodIngredient_SeaUrchinOpen.gltf", "scale": 0.9},
	"avocado": {"name": "Avocado", "model": KIT + "Food/glTF/FoodIngredient_Avocado.gltf", "scale": 1.0},
	"crab": {"name": "Crab", "model": KIT + "Food/glTF/FoodIngredient_Crabsticks.gltf", "scale": 1.0},
	"eel": {"name": "Eel", "model": KIT + "Food/glTF/FoodIngredient_Eel.gltf", "scale": 1.0},
	"squid": {"name": "Squid", "model": KIT + "Food/glTF/FoodIngredient_Squid.gltf", "scale": 1.0},
	"mackerel": {"name": "Mackerel", "model": KIT + "Food/glTF/FoodIngredient_Shimesaba.gltf", "scale": 1.0},
}

## Station order left to right on the counter.
const STATION_ORDER := ["rice", "nori", "salmon", "tuna", "ebi", "cucumber", "egg", "tentacle", "urchin", "avocado", "crab", "eel", "squid", "mackerel"]
const DISH_SCENES := "res://scenes/dishes/"

## Dish id -> name, finished model, ingredient set, price.
const DISHES := {
	"salmon_nigiri": {"name": "Salmon Nigiri", "model": KIT + "Food/glTF/Food_SalmonNigiri.gltf", "ingredients": ["rice", "salmon"], "price": 8},
	"maguro_nigiri": {"name": "Maguro Nigiri", "model": KIT + "Food/glTF/Food_MaguroNigiri.gltf", "ingredients": ["rice", "tuna"], "price": 8},
	"ebi_nigiri": {"name": "Ebi Nigiri", "model": KIT + "Food/glTF/Food_EbiNigiri.gltf", "ingredients": ["rice", "ebi"], "price": 9},
	"tamago_nigiri": {"name": "Tamago Nigiri", "model": KIT + "Food/glTF/Food_TamagoNigiri.gltf", "ingredients": ["rice", "egg"], "price": 7},
	"octopus_nigiri": {"name": "Octopus Nigiri", "model": KIT + "Food/glTF/Food_OctopusNigiri.gltf", "ingredients": ["rice", "tentacle"], "price": 10},
	"onigiri": {"name": "Onigiri", "model": KIT + "Food/glTF/Food_Onigiri.gltf", "ingredients": ["rice", "nori"], "price": 6},
	"cucumber_roll": {"name": "Cucumber Roll", "model": KIT + "Food/glTF/Food_Roll.gltf", "ingredients": ["rice", "nori", "cucumber"], "price": 11},
	"salmon_roll": {"name": "Salmon Roll", "model": KIT + "Food/glTF/Food_SalmonRoll.gltf", "ingredients": ["rice", "nori", "salmon"], "price": 12},
	"urchin_roll": {"name": "Sea Urchin Roll", "model": KIT + "Food/glTF/Food_SeaUrchinRoll.gltf", "ingredients": ["rice", "nori", "urchin"], "price": 14},
	"avocado_roll": {"name": "Avocado Roll", "model": DISH_SCENES + "avocado_roll.tscn", "ingredients": ["rice", "nori", "avocado"], "price": 12},
	"crab_roll": {"name": "Crab Roll", "model": DISH_SCENES + "crab_roll.tscn", "ingredients": ["rice", "nori", "crab"], "price": 13},
	"eel_nigiri": {"name": "Unagi Nigiri", "model": DISH_SCENES + "eel_nigiri.tscn", "ingredients": ["rice", "eel"], "price": 11},
	"squid_nigiri": {"name": "Squid Nigiri", "model": DISH_SCENES + "squid_nigiri.tscn", "ingredients": ["rice", "squid"], "price": 10},
	"mackerel_nigiri": {"name": "Saba Nigiri", "model": DISH_SCENES + "mackerel_nigiri.tscn", "ingredients": ["rice", "mackerel"], "price": 10},
}

const MAX_INGREDIENTS := 3
const SLOT_STEP := 1.8


## X positions for `count` stations in centre-out order (the pass sits in the gap at X 0), so the
## first ingredients in STATION_ORDER — rice and nori, which every recipe needs — sit beside the pass.
## The narrow room has 5 slots per side; the wide room (days 4-5) 8 on the left and 6 on the right,
## because its sink moves to the right end of the counter.
static func station_slots(count: int, wide: bool) -> Array:
	var left := 8 if wide else 5
	var right := 6 if wide else 5
	var xs: Array = []
	for i in range(1, maxi(left, right) + 1):
		if i <= left:
			xs.append(-SLOT_STEP * i)
		if i <= right:
			xs.append(SLOT_STEP * i)
	return xs.slice(0, mini(count, xs.size()))

static var _scene_cache: Dictionary = {}


static func load_model(path: String) -> PackedScene:
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path]


## Returns the dish id whose ingredient set equals `ingredients`, or "".
static func match_dish(ingredients: Array) -> String:
	var sorted := ingredients.duplicate()
	sorted.sort()
	for id in DISHES:
		var need: Array = DISHES[id]["ingredients"].duplicate()
		need.sort()
		if need == sorted:
			return id
	return ""


## True when `ingredients` is a strict subset of at least one recipe (still buildable).
static func is_prefix(ingredients: Array) -> bool:
	if ingredients.is_empty():
		return true
	for id in DISHES:
		var need: Array = DISHES[id]["ingredients"]
		var ok := true
		for i in ingredients:
			if not need.has(i):
				ok = false
				break
		if ok and need.size() > ingredients.size():
			return true
	return false


static func dish_name(id: String) -> String:
	return DISHES[id]["name"] if DISHES.has(id) else ""


static func dish_price(id: String) -> int:
	return int(DISHES[id]["price"]) if DISHES.has(id) else 0
