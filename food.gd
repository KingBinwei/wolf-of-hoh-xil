extends Area2D
class_name FoodItem

enum FoodType { BURGER, EGG_TART, BONE, FISH }

var food_type: FoodType = FoodType.BURGER
var lifetime: float = 10.0
var age: float = 0.0

const HUNGER_RESTORE := {
	FoodType.BURGER: 40.0,
	FoodType.EGG_TART: 25.0,
	FoodType.BONE: 30.0,
	FoodType.FISH: 35.0
}

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	# Collision shape for area detection by wolf hitbox.
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape_node.shape = circle
	add_child(shape_node)

func configure(p_type: FoodType, p_position: Vector2) -> void:
	food_type = p_type
	global_position = p_position
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	# Fade out in last 2 seconds
	if age >= lifetime - 2.0:
		modulate.a = lerpf(1.0, 0.0, (age - (lifetime - 2.0)) / 2.0)

func _draw() -> void:
	var s: float = 14.0  # base size
	match food_type:
		FoodType.BURGER:
			# Top bun (brown dome)
			draw_circle(Vector2(0, -3), s * 0.85, Color(0.6, 0.35, 0.15))
			# Lettuce (green)
			draw_circle(Vector2(0, 2), s * 0.7, Color(0.25, 0.7, 0.2))
			# Tomato (red)
			draw_circle(Vector2(0, 5), s * 0.45, Color(0.85, 0.2, 0.15))
			# Bottom bun
			draw_rect(Rect2(-s * 0.5, 5, s, 5), Color(0.55, 0.3, 0.1))
		FoodType.EGG_TART:
			# Crust (brown ring)
			draw_circle(Vector2.ZERO, s, Color(0.65, 0.4, 0.2))
			# Egg filling (yellow)
			draw_circle(Vector2(0, -1), s * 0.7, Color(0.95, 0.85, 0.25))
		FoodType.BONE:
			# Shaft
			draw_rect(Rect2(-s * 0.8, -3, s * 1.6, 6), Color(0.92, 0.9, 0.85))
			# End knobs
			draw_circle(Vector2(-s * 0.8, 0), 4, Color(0.92, 0.9, 0.85))
			draw_circle(Vector2(s * 0.8, 0), 4, Color(0.92, 0.9, 0.85))
		FoodType.FISH:
			# Body (blue-gray oval)
			draw_rect(Rect2(-s * 0.9, -4, s * 1.8, 8), Color(0.5, 0.6, 0.7))
			# Tail
			draw_circle(Vector2(s * 0.9, 0), 5, Color(0.5, 0.6, 0.7))
			# Eye
			draw_circle(Vector2(-s * 0.5, -2), 2, Color(0.1, 0.1, 0.1))

func get_hunger_restore() -> float:
	return HUNGER_RESTORE.get(food_type, 20.0)
