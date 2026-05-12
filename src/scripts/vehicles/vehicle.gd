extends Area2D
class_name Vehicle

enum VehicleType {
	BUS,
	PICKUP,
	TRUCK,
	SUV,
	SEDAN,
	SPORTS
}

# Behavior classification per vehicle type
const BEHAVIOR := {
	VehicleType.SUV:    {"can_slow": true,  "can_throw": true,  "is_lethal": false, "wind_push": 1.0,  "label": "SUV"},
	VehicleType.PICKUP: {"can_slow": true,  "can_throw": true,  "is_lethal": false, "wind_push": 1.0,  "label": "Pickup"},
	VehicleType.SEDAN:  {"can_slow": false, "can_throw": false, "is_lethal": false, "wind_push": 0.6,  "label": "Sedan"},
	VehicleType.SPORTS: {"can_slow": false, "can_throw": false, "is_lethal": false, "wind_push": 0.4,  "label": "Sports"},
	VehicleType.BUS:    {"can_slow": false, "can_throw": false, "is_lethal": true,  "wind_push": 2.0,  "label": "Bus"},
	VehicleType.TRUCK:  {"can_slow": false, "can_throw": false, "is_lethal": true,  "wind_push": 3.0,  "label": "Truck"},
}

const VEHICLES_LAYER_MASK := 1

var vehicle_type: VehicleType = VehicleType.SEDAN
var direction: float = 1.0
var speed_px_s: float = 120.0

var size_x_px: float = 60.0
var size_y_px: float = 35.0
var vehicle_color: Color = Color(0.8, 0.8, 0.8, 1.0)

var asphalt_y_min: float = 0.0
var asphalt_y_max: float = 0.0
var offscreen_margin_px: float = 120.0

var is_decelerating: bool = false
var has_thrown_food: bool = false
var _target_speed: float = 0.0
var _decel_rate: float = 60.0

@onready var collision_shape: CollisionShape2D = CollisionShape2D.new()

func _ready() -> void:
	if not has_node("CollisionShape2D"):
		add_child(collision_shape)
		collision_shape.name = "CollisionShape2D"
	else:
		collision_shape = get_node("CollisionShape2D") as CollisionShape2D

	collision_layer = VEHICLES_LAYER_MASK
	collision_mask = 0
	z_index = 5
	_update_collision_and_redraw()

func configure(
		p_type: VehicleType,
		p_direction: float,
		p_speed_px_s: float,
		p_size_x_px: float,
		p_size_y_px: float,
		p_color: Color,
		p_asphalt_y_min: float,
		p_asphalt_y_max: float
	) -> void:
	vehicle_type = p_type
	direction = sign(p_direction)
	speed_px_s = p_speed_px_s
	size_x_px = p_size_x_px
	size_y_px = p_size_y_px
	vehicle_color = p_color
	asphalt_y_min = p_asphalt_y_min
	asphalt_y_max = p_asphalt_y_max
	_update_collision_and_redraw()

func _update_collision_and_redraw() -> void:
	if is_instance_valid(collision_shape):
		if collision_shape.shape == null:
			collision_shape.shape = RectangleShape2D.new()
		(collision_shape.shape as RectangleShape2D).size = Vector2(size_x_px, size_y_px)
	queue_redraw()

func get_behavior(key: String) -> Variant:
	return BEHAVIOR.get(vehicle_type, {}).get(key, false)

func is_lethal() -> bool:
	return get_behavior("is_lethal")

func can_slow_down() -> bool:
	return get_behavior("can_slow")

func can_throw_food() -> bool:
	return get_behavior("can_throw")

func get_wind_push_strength() -> float:
	return float(get_behavior("wind_push"))

func start_decelerating(target_frac: float) -> void:
	if not can_slow_down():
		return
	is_decelerating = true
	_target_speed = speed_px_s * target_frac

func _process(delta: float) -> void:
	if is_decelerating:
		speed_px_s = move_toward(speed_px_s, _target_speed, _decel_rate * delta)
		if speed_px_s <= _target_speed + 1.0:
			speed_px_s = _target_speed
			is_decelerating = false

	global_position.y += speed_px_s * direction * delta

	if direction < 0.0:
		if global_position.y < asphalt_y_min - offscreen_margin_px:
			queue_free()
	else:
		if global_position.y > asphalt_y_max + offscreen_margin_px:
			queue_free()

func _draw() -> void:
	var w: float = size_x_px
	var h: float = size_y_px
	var r: Rect2 = Rect2(-w * 0.5, -h * 0.5, w, h)

	draw_rect(r, vehicle_color, true)
	draw_rect(r, Color(0, 0, 0, 0.35), false, 2)

	var wheel_color: Color = Color(0.12, 0.12, 0.12, 1.0)
	var wheel_radius: float = minf(6.0, maxf(3.0, minf(w, h) * 0.12))
	draw_circle(Vector2(-w * 0.35, -h * 0.38), wheel_radius, wheel_color)
	draw_circle(Vector2(w * 0.35, -h * 0.38), wheel_radius, wheel_color)
	draw_circle(Vector2(-w * 0.35, h * 0.38), wheel_radius, wheel_color)
	draw_circle(Vector2(w * 0.35, h * 0.38), wheel_radius, wheel_color)

	var stripe: Color = Color(0.05, 0.05, 0.05, 0.65)
	match vehicle_type:
		VehicleType.BUS:
			draw_rect(Rect2(-w * 0.45, -h * 0.05, w * 0.9, h * 0.1), stripe, true)
			draw_line(Vector2(-w * 0.45, h * 0.12), Vector2(w * 0.45, h * 0.12), stripe, 3)
		VehicleType.PICKUP:
			draw_rect(Rect2(-w * 0.45, -h * 0.28, w * 0.9, h * 0.1), stripe, true)
		VehicleType.TRUCK:
			draw_rect(Rect2(-w * 0.45, -h * 0.18, w * 0.9, h * 0.1), stripe, true)
			draw_line(Vector2(0, -h * 0.22), Vector2(0, h * 0.25), stripe, 3)
			# Extra long trailer indicator for heavy trucks
			draw_rect(Rect2(-w * 0.48, h * 0.3, w * 0.96, h * 0.15), stripe, true)
		VehicleType.SUV:
			draw_rect(Rect2(-w * 0.45, -h * 0.1, w * 0.9, h * 0.2), stripe, true)
		VehicleType.SEDAN:
			draw_rect(Rect2(-w * 0.4, -h * 0.08, w * 0.8, h * 0.16), stripe, true)
		VehicleType.SPORTS:
			draw_line(Vector2(-w * 0.2, -h * 0.4), Vector2(w * 0.2, h * 0.4), stripe, 4)
