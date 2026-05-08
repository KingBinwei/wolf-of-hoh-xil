extends Node2D

@export var spawn_interval_base_s: float = 1.8
@export var spawn_interval_jitter_s: float = 0.6

@export var spawn_margin_y_px: float = 70.0
@export var offscreen_margin_px: float = 140.0

@export var vehicle_speed_min_px_s: float = 70.0
@export var vehicle_speed_max_px_s: float = 160.0
@export var min_gap_between_vehicles_s: float = 1.5

const VEHICLE_TYPES := [
	Vehicle.VehicleType.BUS,
	Vehicle.VehicleType.PICKUP,
	Vehicle.VehicleType.TRUCK,
	Vehicle.VehicleType.SUV,
	Vehicle.VehicleType.SEDAN,
	Vehicle.VehicleType.SPORTS
]

const RNG_SEED_OFFSET := 1337

var _start_time_s: float = 0.0
var _asphalt_rect: Rect2
var _lane_centers_x: PackedFloat32Array = PackedFloat32Array()
var _lane_dirs: Array[float] = []
var _lane_next_spawn_time_s: Array[float] = []

func configure(
		asphalt_rect: Rect2,
		_wolf_y: float,
		_wolf_y_band_half_px_in: float,
		_lane_clear_time_fraction: float = 1.0
	) -> void:
	_asphalt_rect = asphalt_rect

	# 4 lanes across the asphalt width: left two lanes -> up-moving; right two -> down-moving.
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
		_lane_next_spawn_time_s[i] = randf_range(0.2, 0.8) + float(i) * 0.15

func start_spawning() -> void:
	_start_time_s = Time.get_ticks_msec() / 1000.0
	set_process(true)

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	var now_s := Time.get_ticks_msec() / 1000.0 - _start_time_s
	var lane_w := _asphalt_rect.size.x / 4.0

	for lane in range(4):
		if now_s < _lane_next_spawn_time_s[lane]:
			continue

		var v_type: Vehicle.VehicleType = VEHICLE_TYPES[randi() % VEHICLE_TYPES.size()]
		var v_speed: float = randf_range(vehicle_speed_min_px_s, vehicle_speed_max_px_s)
		var dims: Dictionary = _vehicle_dims_for_type(v_type, lane_w)
		var size_x: float = float(dims["size_x"])
		var size_y: float = float(dims["size_y"])
		var dir: float = float(_lane_dirs[lane])

		# Spawn above the road for up-moving (-1), below for down-moving (+1).
		var spawn_y: float = (_asphalt_rect.position.y + _asphalt_rect.size.y + spawn_margin_y_px) if dir < 0.0 else (_asphalt_rect.position.y - spawn_margin_y_px)

		_spawn_vehicle(
			lane, dir, v_type, v_speed, size_x, size_y,
			_random_vehicle_color(v_type), spawn_y
		)

		var interval: float = randf_range(
			spawn_interval_base_s - spawn_interval_jitter_s,
			spawn_interval_base_s + spawn_interval_jitter_s
		)
		_lane_next_spawn_time_s[lane] = now_s + max(min_gap_between_vehicles_s, interval)

func _vehicle_dims_for_type(v_type: Vehicle.VehicleType, lane_w: float) -> Dictionary:
	var w := lane_w
	match v_type:
		Vehicle.VehicleType.BUS:
			return {"size_x": w * 0.88, "size_y": 74.0}
		Vehicle.VehicleType.PICKUP:
			return {"size_x": w * 0.72, "size_y": 48.0}
		Vehicle.VehicleType.TRUCK:
			return {"size_x": w * 0.80, "size_y": 60.0}
		Vehicle.VehicleType.SUV:
			return {"size_x": w * 0.76, "size_y": 56.0}
		Vehicle.VehicleType.SEDAN:
			return {"size_x": w * 0.66, "size_y": 40.0}
		Vehicle.VehicleType.SPORTS:
			return {"size_x": w * 0.58, "size_y": 34.0}
		_:
			return {"size_x": w * 0.7, "size_y": 42.0}

func _spawn_vehicle(
		lane: int,
		dir: float,
		v_type: Vehicle.VehicleType,
		speed: float,
		size_x: float,
		size_y: float,
		color: Color,
		spawn_y: float
	) -> void:
	var vehicle := Vehicle.new()
	vehicle.vehicle_type = v_type
	vehicle.name = "Vehicle_%s_L%d" % [str(v_type), lane]
	vehicle.global_position = Vector2(_lane_centers_x[lane], spawn_y)

	add_child(vehicle)

	vehicle.z_index = 6
	vehicle.offscreen_margin_px = offscreen_margin_px
	vehicle.configure(
		v_type,
		dir,
		speed,
		size_x,
		size_y,
		color,
		_asphalt_rect.position.y,
		_asphalt_rect.position.y + _asphalt_rect.size.y
	)

func _random_vehicle_color(v_type: Vehicle.VehicleType) -> Color:
	match v_type:
		Vehicle.VehicleType.BUS:
			return Color(0.45, 0.65, 0.85, 1.0)
		Vehicle.VehicleType.PICKUP:
			return Color(0.9, 0.65, 0.3, 1.0)
		Vehicle.VehicleType.TRUCK:
			return Color(0.7, 0.7, 0.75, 1.0)
		Vehicle.VehicleType.SUV:
			return Color(0.35, 0.8, 0.55, 1.0)
		Vehicle.VehicleType.SEDAN:
			return Color(0.88, 0.3, 0.3, 1.0)
		Vehicle.VehicleType.SPORTS:
			return Color(0.55, 0.45, 0.95, 1.0)
		_:
			return Color(0.8, 0.8, 0.8, 1.0)
