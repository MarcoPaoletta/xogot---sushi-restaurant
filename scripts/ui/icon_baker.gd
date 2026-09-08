extends SubViewport
## Renders a 3D model once into a small texture, for the recipe book. Results are cached per session.

static var _cache: Dictionary = {}
@onready var slot: Node3D = $Slot
var _busy := false


func bake(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	while _busy:
		await get_tree().process_frame
	_busy = true
	var scene := Recipes.load_model(path)
	if scene == null:
		_busy = false
		return null
	var m: Node3D = scene.instantiate()
	slot.add_child(m)
	var aabb := _merged_aabb(m)
	var longest := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var s := 1.0 / maxf(longest, 0.01)
	m.scale = Vector3.ONE * s
	m.position = -aabb.get_center() * s
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var tex := ImageTexture.create_from_image(get_texture().get_image())
	m.queue_free()
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_cache[path] = tex
	_busy = false
	return tex


func _merged_aabb(root: Node) -> AABB:
	var result := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mi.get_aabb()
		var xf: Transform3D = root.global_transform.affine_inverse() * mi.global_transform
		var world := xf * box
		if first:
			result = world
			first = false
		else:
			result = result.merge(world)
	return result if not first else AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE)
