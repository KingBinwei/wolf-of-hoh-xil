extends Node2D

signal wolf_detected

var wolf_node: Node2D
var asphalt_rect: Rect2
var vehicles_collision_layer_mask: int = 1
var cone_direction: Vector2 = Vector2.RIGHT

@export var ranger_y_amp_px: float = 80.0
@export var ranger_y_speed_hz: float = 0.5

var ranger_base_y: float = 0.0

var cone_range_px: float = 600.0
var cone_half_angle_rad: float = 0.6
var cone_color: Color = Color(0.95, 0.2, 0.2, 0.12)
var cone_blocked_color: Color = Color(0.95, 0.2, 0.2, 0.24)

var _cone_samples: int = 28
var _vision_update_interval_s: float = 0.08
var _vision_accum: float = 0.0

var _detected := false

func configure(
		p_wolf_node: Node2D,
		p_asphalt_rect: Rect2,
		p_cone_range_px: float,
		p_viewport_size: Vector2,
		p_cone_direction: Vector2 = Vector2.RIGHT
	) -> void:
	wolf_node = p_wolf_node
	asphalt_rect = p_asphalt_rect
	cone_range_px = max(40.0, p_cone_range_px)
	cone_direction = p_cone_direction.normalized()

	# Cone occupies ~1/3 of the screen at the far end.
	var base_width_px := p_viewport_size.x / 3.0
	var half_w := base_width_px * 0.5
	cone_half_angle_rad = atan2(half_w, cone_range_px)
	# Keep a practical stealth-game cone; avoid ultra-wide instant detection.
	cone_half_angle_rad = clampf(cone_half_angle_rad, deg_to_rad(6.0), deg_to_rad(22.0))

	vehicles_collision_layer_mask = 1

	# Ranger "slow" vertical movement.
	ranger_base_y = global_position.y

func _process(delta: float) -> void:
	if _detected or not is_instance_valid(wolf_node):
		return

	# Slow vertical drift.
	var t := Time.get_ticks_msec() / 1000.0
	global_position.y = ranger_base_y + sin(t * TAU * ranger_y_speed_hz) * ranger_y_amp_px

	# Update cone visuals and do detection at a limited rate.
	_vision_accum += delta
	if _vision_accum >= _vision_update_interval_s:
		_vision_accum = 0.0
		_update_cone_and_detect()

func _update_cone_and_detect() -> void:
	queue_redraw()

	var wolf_pos := wolf_node.global_position
	var dir_to_wolf := wolf_pos - global_position
	var dist_to_wolf := dir_to_wolf.length()
	if dist_to_wolf <= 0.001:
		return

	if dist_to_wolf > cone_range_px:
		return

	# Cone angle check.
	var dir_norm := dir_to_wolf / dist_to_wolf
	var angle := acos(clampf(cone_direction.dot(dir_norm), -1.0, 1.0))
	if angle > cone_half_angle_rad:
		return

	# Line-of-sight: raycast to wolf; if a vehicle hits first, vision is blocked.
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = wolf_pos
	query.exclude = [self, wolf_node]
	query.collision_mask = vehicles_collision_layer_mask
	query.hit_from_inside = false

	var res := space_state.intersect_ray(query)
	if not res.is_empty():
		# Something on the ray path blocks vision.
		return

	# Not blocked => detect wolf.
	_detected = true
	wolf_detected.emit()

func _draw() -> void:
	# Cone polygon, with approximate occlusion by casting rays to vehicles.
	if _detected or not is_instance_valid(wolf_node):
		return

	var points := PackedVector2Array()
	var base_angle := atan2(cone_direction.y, cone_direction.x)

	# Sample rays across the cone.
	for i in range(_cone_samples + 1):
		var u: float = float(i) / float(_cone_samples)
		var a: float = base_angle + lerpf(-cone_half_angle_rad, cone_half_angle_rad, u)
		var dir: Vector2 = Vector2(cos(a), sin(a)) # Godot 2D: y grows downward, sin() stays consistent.
		var ray_dir := dir.normalized()

		var ray_to := global_position + ray_dir * cone_range_px
		var space_state := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.new()
		query.from = global_position
		query.to = ray_to
		query.exclude = [self, wolf_node]
		query.collision_mask = vehicles_collision_layer_mask
		query.hit_from_inside = false

		var res := space_state.intersect_ray(query)
		var dist := cone_range_px
		if not res.is_empty():
			dist = global_position.distance_to(res.position)

		points.append(ray_dir * dist)

	# Fill cone.
	if points.size() >= 2:
		# Points are in global space; convert to local for draw_polygon.
		var poly_local := PackedVector2Array()
		poly_local.append(Vector2.ZERO) # apex
		for p in points:
			poly_local.append(p - global_position)

		var colors := PackedColorArray()
		colors.resize(poly_local.size())
		for idx in range(poly_local.size()):
			colors[idx] = cone_color

		draw_polygon(poly_local, colors, [])
