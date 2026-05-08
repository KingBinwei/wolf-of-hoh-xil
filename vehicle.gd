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

const VEHICLES_LAYER_MASK := 1 # keep simple: raycast/occlusion uses this

var vehicle_type: VehicleType = VehicleType.SEDAN
var direction: float = 1.0 # +1 down, -1 up (Godot Y grows down)
var speed_px_s: float = 120.0

var size_x_px: float = 60.0
var size_y_px: float = 35.0
var vehicle_color: Color = Color(0.8, 0.8, 0.8, 1.0)

var asphalt_y_min: float = 0.0
var asphalt_y_max: float = 0.0
var offscreen_margin_px: float = 120.0

@onready var collision_shape: CollisionShape2D = CollisionShape2D.new()

func _ready() -> void:
	# Ensure we have a collision shape so rays can occlude vision.
	if not has_node("CollisionShape2D"):
		add_child(collision_shape)
		collision_shape.name = "CollisionShape2D"
	else:
		collision_shape = get_node("CollisionShape2D") as CollisionShape2D

	collision_layer = VEHICLES_LAYER_MASK
	collision_mask = 0 # no physical collisions; we only use it for raycast occlusion
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

func _process(delta: float) -> void:
	global_position.y += speed_px_s * direction * delta

	# Remove when it leaves the road vertically.
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

	# Body
	draw_rect(r, vehicle_color, true)
	draw_rect(r, Color(0, 0, 0, 0.35), false, 2)

	# Wheels (top-down circles)
	var wheel_color: Color = Color(0.12, 0.12, 0.12, 1.0)
	var wheel_radius: float = minf(6.0, maxf(3.0, minf(w, h) * 0.12))
	var left_wheel: Vector2 = Vector2(-w * 0.35, -h * 0.38)
	var right_wheel: Vector2 = Vector2(w * 0.35, -h * 0.38)
	var back_left: Vector2 = Vector2(-w * 0.35, h * 0.38)
	var back_right: Vector2 = Vector2(w * 0.35, h * 0.38)
	draw_circle(left_wheel, wheel_radius, wheel_color)
	draw_circle(right_wheel, wheel_radius, wheel_color)
	draw_circle(back_left, wheel_radius, wheel_color)
	draw_circle(back_right, wheel_radius, wheel_color)

	# Type hint stripes to differentiate shapes.
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
		VehicleType.SUV:
			draw_rect(Rect2(-w * 0.45, -h * 0.1, w * 0.9, h * 0.2), stripe, true)
		VehicleType.SEDAN:
			draw_rect(Rect2(-w * 0.4, -h * 0.08, w * 0.8, h * 0.16), stripe, true)
		VehicleType.SPORTS:
			draw_line(Vector2(-w * 0.2, -h * 0.4), Vector2(w * 0.2, h * 0.4), stripe, 4)
