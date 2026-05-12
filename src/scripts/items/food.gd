extends Area2D
class_name FoodItem

enum FoodType {
	# Human food — highway throwables (Chapter 1+)
	STARCH_SAUSAGE,   # 淀粉肠 — cheap, common
	COLD_BREAD,       # 冷馒头 — cheap, common
	FRIED_STARCH,     # 油炸淀粉块 — oily, medium rarity
	ROAST_CHICKEN,    # 烧鸡 — rare, high value, thrown on yellow lines
	RAW_MEAT,         # 生肉块 — rarest throwable, almost no penalty
	# Wild food — wilderness hunting (Chapter 2+)
	PIKA,             # 鼠兔
	MARMOT,           # 旱獭
	INJURED_GAZELLE,  # 受伤藏原羚
	CARCASS           # 腐肉/倒毙牦牛
}

enum FoodSource { HIGHWAY, WILD }

var food_type: FoodType = FoodType.STARCH_SAUSAGE
var lifetime: float = 10.0
var age: float = 0.0

const HUNGER_RESTORE := {
	FoodType.STARCH_SAUSAGE: 25.0,
	FoodType.COLD_BREAD: 20.0,
	FoodType.FRIED_STARCH: 30.0,
	FoodType.ROAST_CHICKEN: 45.0,
	FoodType.RAW_MEAT: 35.0,
	FoodType.PIKA: 15.0,
	FoodType.MARMOT: 25.0,
	FoodType.INJURED_GAZELLE: 40.0,
	FoodType.CARCASS: 50.0,
}

const WILDNESS_PENALTY := {
	FoodType.STARCH_SAUSAGE: -5.0,
	FoodType.COLD_BREAD: -3.0,
	FoodType.FRIED_STARCH: -5.0,
	FoodType.ROAST_CHICKEN: -2.0,
	FoodType.RAW_MEAT: -1.0,
	FoodType.PIKA: 3.0,
	FoodType.MARMOT: 5.0,
	FoodType.INJURED_GAZELLE: 8.0,
	FoodType.CARCASS: 2.0,
}

const MUSCLE_PENALTY := {
	FoodType.STARCH_SAUSAGE: -1.0,
	FoodType.COLD_BREAD: -1.0,
	FoodType.FRIED_STARCH: -1.0,
	FoodType.ROAST_CHICKEN: -0.5,
	FoodType.RAW_MEAT: 0.0,
	FoodType.PIKA: 0.0,
	FoodType.MARMOT: 0.0,
	FoodType.INJURED_GAZELLE: 0.0,
	FoodType.CARCASS: 0.0,
}

const FOOD_SOURCE := {
	FoodType.STARCH_SAUSAGE: FoodSource.HIGHWAY,
	FoodType.COLD_BREAD: FoodSource.HIGHWAY,
	FoodType.FRIED_STARCH: FoodSource.HIGHWAY,
	FoodType.ROAST_CHICKEN: FoodSource.HIGHWAY,
	FoodType.RAW_MEAT: FoodSource.HIGHWAY,
	FoodType.PIKA: FoodSource.WILD,
	FoodType.MARMOT: FoodSource.WILD,
	FoodType.INJURED_GAZELLE: FoodSource.WILD,
	FoodType.CARCASS: FoodSource.WILD,
}

const HIGHWAY_FOOD_TYPES: Array[FoodType] = [
	FoodType.STARCH_SAUSAGE,
	FoodType.COLD_BREAD,
	FoodType.FRIED_STARCH,
	FoodType.ROAST_CHICKEN,
	FoodType.RAW_MEAT,
]

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
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
	if age >= lifetime - 2.0:
		modulate.a = lerpf(1.0, 0.0, (age - (lifetime - 2.0)) / 2.0)

func _draw() -> void:
	var s: float = 14.0
	match food_type:
		FoodType.STARCH_SAUSAGE:
			# Orange-red plastic casing with pink paste visible at cut
			draw_rect(Rect2(-s * 0.5, -s * 0.35, s, s * 0.7), Color(0.9, 0.35, 0.15), true)
			draw_rect(Rect2(s * 0.3, -s * 0.2, s * 0.25, s * 0.4), Color(0.95, 0.75, 0.7), true)
			draw_rect(Rect2(-s * 0.5, -s * 0.35, s, s * 0.7), Color(0.7, 0.2, 0.05), false, 1)
		FoodType.COLD_BREAD:
			# Pale white-grey馒头 with a slightly rough surface
			draw_circle(Vector2(0, 0), s * 0.75, Color(0.88, 0.85, 0.80))
			draw_arc(Vector2(0, -s * 0.3), s * 0.5, 0, PI, 5, Color(0.82, 0.79, 0.74), 2)
		FoodType.FRIED_STARCH:
			# Golden-brown irregular chunks
			draw_rect(Rect2(-s * 0.6, -s * 0.5, s * 1.2, s * 1.0), Color(0.82, 0.55, 0.20), true)
			draw_rect(Rect2(-s * 0.4, -s * 0.6, s * 0.5, s * 0.4), Color(0.90, 0.65, 0.25), true)
			draw_rect(Rect2(-s * 0.55, s * 0.1, s * 1.1, s * 0.35), Color(0.72, 0.45, 0.15), true)
		FoodType.ROAST_CHICKEN:
			# Brown roasted meat with bone
			draw_circle(Vector2(0, -s * 0.2), s * 0.65, Color(0.55, 0.30, 0.12))
			draw_rect(Rect2(-s * 0.2, -s * 0.4, s * 0.4, s * 1.0), Color(0.50, 0.28, 0.10), true)
			draw_circle(Vector2(0, s * 0.5), s * 0.25, Color(0.90, 0.85, 0.80))  # bone end
		FoodType.RAW_MEAT:
			# Dark red muscle with white fat edge
			draw_rect(Rect2(-s * 0.5, -s * 0.4, s * 0.8, s * 0.8), Color(0.65, 0.12, 0.08), true)
			draw_rect(Rect2(-s * 0.5, -s * 0.4, s, s * 0.2), Color(0.92, 0.88, 0.82), true)
			draw_rect(Rect2(-s * 0.5, -s * 0.4, s * 0.8, s * 0.8), Color(0.45, 0.05, 0.02), false, 1)
		FoodType.PIKA:
			draw_circle(Vector2(0, 0), s * 0.55, Color(0.55, 0.45, 0.35))
			draw_circle(Vector2(-s * 0.25, -s * 0.2), 2, Color(0.1, 0.1, 0.1))
		FoodType.MARMOT:
			draw_circle(Vector2(0, 0), s * 0.7, Color(0.50, 0.40, 0.30))
			draw_rect(Rect2(-s * 0.5, -s * 0.1, s, s * 0.4), Color(0.45, 0.35, 0.25), true)
		FoodType.INJURED_GAZELLE:
			draw_rect(Rect2(-s * 0.7, -s * 0.5, s * 1.4, s * 1.0), Color(0.60, 0.30, 0.15), true)
			draw_circle(Vector2(0, s * 0.3), s * 0.3, Color(0.75, 0.15, 0.10))
		FoodType.CARCASS:
			draw_rect(Rect2(-s * 0.6, -s * 0.3, s * 1.2, s * 0.6), Color(0.35, 0.25, 0.18), true)
			draw_circle(Vector2(-s * 0.4, -s * 0.15), 3, Color(0.55, 0.45, 0.35))
			draw_line(Vector2(-s * 0.4, s * 0.3), Vector2(s * 0.4, s * 0.3), Color(0.25, 0.18, 0.12), 2)

func get_hunger_restore() -> float:
	return HUNGER_RESTORE.get(food_type, 20.0)

func get_wildness_change() -> float:
	return WILDNESS_PENALTY.get(food_type, 0.0)

func get_muscle_change() -> float:
	return MUSCLE_PENALTY.get(food_type, 0.0)

func get_food_source() -> int:
	return FOOD_SOURCE.get(food_type, FoodSource.HIGHWAY)

func is_human_food() -> bool:
	return get_food_source() == FoodSource.HIGHWAY
