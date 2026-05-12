extends Node2D

const VehicleScript := preload("res://src/scripts/vehicles/vehicle.gd")

# Vehicle type enum values (mirrors Vehicle.VehicleType)
const VT_SUV: int    = 3
const VT_PICKUP: int = 1
const VT_SEDAN: int  = 4
const VT_SPORTS: int = 5
const VT_BUS: int    = 0
const VT_TRUCK: int  = 2

const SPAWN_WEIGHTS := {
	VT_SUV: 3.0,
	VT_PICKUP: 2.5,
	VT_SEDAN: 2.0,
	VT_SPORTS: 0.8,
	VT_BUS: 0.6,
	VT_TRUCK: 1.0,
}

@export var spawn_interval_base_s: float = 1.8
@export var spawn_interval_jitter_s: float = 0.6
@export var spawn_margin_y_px: float = 70.0
@export var offscreen_margin_px: float = 140.0
@export var vehicle_speed_min_px_s: float = 70.0
@export var vehicle_speed_max_px_s: float = 160.0
@export var min_gap_between_vehicles_s: float = 1.5

@export var suv_slow_trigger_distance: float = 180.0
@export var suv_slow_fraction: float = 0.25
@export var suv_throw_food_chance: float = 0.40
@export var suv_photo_flash_chance: float = 0.35

@export var wind_push_distance: float = 100.0
@export var wind_push_force: float = 350.0

# Highway food types for thrown food
const HIGHWAY_FOOD_TYPES: Array = [0, 1, 2, 3, 4]

var _start_time_s: float = 0.0
var _asphalt_rect: Rect2
var _lane_centers_x: PackedFloat32Array = PackedFloat32Array()
var _lane_dirs: Array[float] = []
var _lane_next_spawn_time_s: Array[float] = []
var _active_vehicles: Array = []
var _wolf_ref: Node2D = null

signal food_thrown_by_vehicle(food_type: int, position: Vector2)
signal vehicle_photo_flash(position: Vector2)

func configure(
		asphalt_rect: Rect2,
		_wolf_y: float,
		_wolf_y_band_half_px_in: float,
		_lane_clear_time_fraction: float = 1.0
	) -> void:
	_asphalt_rect = asphalt_rect

	var lane_w := _asphalt_rect.size.x / 4.0
	_lane_centers_x = PackedFloat32Array()
	_lane_centers_x.resize(4)
	for i in range(4):
		_lane_centers_x[i] = _asphalt_rect.position.x + lane_w * (i + 0.5)

	_lane_dirs = []
	_lane_dirs.resize(4)
	_lane_dirs[0] = -1.0
	_lane_dirs[1] = -1.0
	_lane_dirs[2] = +1.0
	_lane_dirs[3] = +1.0

	_lane_next_spawn_time_s = []
	_lane_next_spawn_time_s.resize(4)
	for i in range(4):
		_lane_next_spawn_time_s[i] = randf_range(0.3, 1.0) + float(i) * 0.15

func set_wolf_reference(wolf: Node2D) -> void:
	_wolf_ref = wolf

func start_spawning() -> void:
	_start_time_s = Time.get_ticks_msec() / 1000.0
	set_process(true)

func _ready() -> void:
	set_process(false)

func _process(delta_f: float) -> void:
	var now_s := Time.get_ticks_msec() / 1000.0 - _start_time_s
	var lane_w := _asphalt_rect.size.x / 4.0

	_active_vehicles = _active_vehicles.filter(func(v): return is_instance_valid(v))

	if is_instance_valid(_wolf_ref):
		_check_suv_interactions()

	if is_instance_valid(_wolf_ref):
		_apply_wind_push(delta_f)

	for lane in range(4):
		if now_s < _lane_next_spawn_time_s[lane]:
			continue

		var v_type: int = _weighted_random_type()
		var v_speed: float = randf_range(vehicle_speed_min_px_s, vehicle_speed_max_px_s)
		var dims: Dictionary = _vehicle_dims_for_type(v_type, lane_w)
		var size_x: float = float(dims["size_x"])
		var size_y: float = float(dims["size_y"])
		var dir: float = float(_lane_dirs[lane])

		var spawn_y: float = (_asphalt_rect.position.y + _asphalt_rect.size.y + spawn_margin_y_px) if dir < 0.0 else (_asphalt_rect.position.y - spawn_margin_y_px)
		_spawn_vehicle(lane, dir, v_type, v_speed, size_x, size_y, _random_color(v_type), spawn_y)

		var interval: float = randf_range(
			spawn_interval_base_s - spawn_interval_jitter_s,
			spawn_interval_base_s + spawn_interval_jitter_s
		)
		_lane_next_spawn_time_s[lane] = now_s + max(min_gap_between_vehicles_s, interval)

func _weighted_random_type() -> int:
	var total: float = 0.0
	for vtype in SPAWN_WEIGHTS:
		total += SPAWN_WEIGHTS[vtype]
	var roll: float = randf() * total
	var accum: float = 0.0
	for vtype in SPAWN_WEIGHTS:
		accum += SPAWN_WEIGHTS[vtype]
		if roll <= accum:
			return vtype
	return VT_SEDAN

func _check_suv_interactions() -> void:
	for vehicle_ref in _active_vehicles:
		var vehicle: Area2D = vehicle_ref as Area2D
		if not is_instance_valid(vehicle):
			continue
		if not vehicle.has_method("can_slow_down") or not vehicle.can_slow_down():
			continue
		if vehicle.is_decelerating:
			continue
		if vehicle.has_thrown_food:
			continue

		var dist_to_wolf: float = absf(vehicle.global_position.y - _wolf_ref.global_position.y)
		if dist_to_wolf > suv_slow_trigger_distance:
			continue

		vehicle.start_decelerating(suv_slow_fraction)

		if randf() < suv_throw_food_chance:
			vehicle.has_thrown_food = true
			var throw_pos := _wolf_ref.global_position + Vector2(
				randf_range(-30.0, 30.0),
				randf_range(-20.0, 20.0)
			)
			var food_type: int = HIGHWAY_FOOD_TYPES[randi() % HIGHWAY_FOOD_TYPES.size()]
			food_thrown_by_vehicle.emit(food_type, throw_pos)

		if randf() < suv_photo_flash_chance:
			vehicle_photo_flash.emit(vehicle.global_position)

func _apply_wind_push(delta: float) -> void:
	for vehicle_ref in _active_vehicles:
		var vehicle: Area2D = vehicle_ref as Area2D
		if not is_instance_valid(vehicle) or not vehicle.has_method("get_wind_push_strength"):
			continue
		var push_strength: float = float(vehicle.get_wind_push_strength())
		if push_strength <= 0.5:
			continue

		var dist_x := absf(vehicle.global_position.x - _wolf_ref.global_position.x)
		var dist_y := absf(vehicle.global_position.y - _wolf_ref.global_position.y)
		if dist_x > wind_push_distance or dist_y > wind_push_distance:
			continue

		var dist := Vector2(dist_x, dist_y).length()
		if dist > wind_push_distance or dist < 1.0:
			continue

		var push_dir: Vector2
		if vehicle.direction < 0.0:
			push_dir = Vector2((_wolf_ref.global_position.x - vehicle.global_position.x) * 0.3, -1.0).normalized()
		else:
			push_dir = Vector2((_wolf_ref.global_position.x - vehicle.global_position.x) * 0.3, 1.0).normalized()

		var force: float = wind_push_force * push_strength * (1.0 - dist / wind_push_distance)
		if _wolf_ref is CharacterBody2D:
			(_wolf_ref as CharacterBody2D).velocity += push_dir * force * delta

func _vehicle_dims_for_type(v_type: int, lane_w: float) -> Dictionary:
	var w := lane_w
	match v_type:
		VT_BUS:    return {"size_x": w * 0.88, "size_y": 74.0}
		VT_PICKUP: return {"size_x": w * 0.72, "size_y": 48.0}
		VT_TRUCK:  return {"size_x": w * 0.80, "size_y": 60.0}
		VT_SUV:    return {"size_x": w * 0.76, "size_y": 56.0}
		VT_SEDAN:  return {"size_x": w * 0.66, "size_y": 40.0}
		VT_SPORTS: return {"size_x": w * 0.58, "size_y": 34.0}
		_:         return {"size_x": w * 0.7, "size_y": 42.0}

func _spawn_vehicle(
		lane: int, dir: float, v_type: int, speed: float,
		size_x: float, size_y: float, color: Color, spawn_y: float
	) -> void:
	var vehicle: Area2D = VehicleScript.new()
	vehicle.call("configure", v_type, dir, speed, size_x, size_y, color,
		_asphalt_rect.position.y, _asphalt_rect.position.y + _asphalt_rect.size.y)
	vehicle.set("vehicle_type", v_type)
	vehicle.name = "Vehicle_L%d" % lane
	vehicle.global_position = Vector2(_lane_centers_x[lane], spawn_y)
	vehicle.z_index = 6
	vehicle.set("offscreen_margin_px", offscreen_margin_px)
	add_child(vehicle)
	_active_vehicles.append(vehicle)

func _random_color(v_type: int) -> Color:
	match v_type:
		VT_BUS:    return Color(0.45, 0.65, 0.85, 1.0)
		VT_PICKUP: return Color(0.9, 0.65, 0.3, 1.0)
		VT_TRUCK:  return Color(0.7, 0.7, 0.75, 1.0)
		VT_SUV:    return Color(0.35, 0.8, 0.55, 1.0)
		VT_SEDAN:  return Color(0.88, 0.3, 0.3, 1.0)
		VT_SPORTS: return Color(0.55, 0.45, 0.95, 1.0)
		_:         return Color(0.8, 0.8, 0.8, 1.0)
