extends CharacterBody2D

signal game_over
signal food_eaten(restore_amount: float)

# Movement
@export var move_speed: float = 200.0

# Wolf status
var health: float = 100.0
var hunger: float = 0.0

@export var hunger_increase_per_second: float = 4.0
@export var health_drain_per_second_when_hungry_full: float = 7.0

# Hit damage
const DAMAGE_PER_HIT: float = 25.0
const INVINCIBLE_DURATION: float = 0.5

var invincible: bool = false
var _invincible_timer: float = 0.0

# Bounds
var asphalt_rect: Rect2

@onready var sprite := get_node_or_null("Sprite2D") as Sprite2D
var _hitbox_shape_size: Vector2 = Vector2(30, 24)

func configure(p_asphalt_rect: Rect2, p_wolf_y: float, p_start_x: float, _p_end_x: float) -> void:
	asphalt_rect = p_asphalt_rect
	health = 100.0
	hunger = 0.0
	invincible = false
	global_position = Vector2(p_start_x, p_wolf_y)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0

	# Create hitbox Area2D for detecting vehicles and food
	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	var hitbox_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = _hitbox_shape_size
	hitbox_shape.shape = shape
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)

	# Detect vehicles (layer 1) and food (layer 2)
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0b11
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if invincible:
		# Only skip vehicle damage, still allow food pickup
		if area is FoodItem:
			_eat_food(area as FoodItem)
		return
	if area is Vehicle:
		_take_damage(DAMAGE_PER_HIT)
	elif area is FoodItem:
		_eat_food(area as FoodItem)

func _take_damage(amount: float) -> void:
	health = clampf(health - amount, 0.0, 100.0)
	invincible = true
	_invincible_timer = INVINCIBLE_DURATION

	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.4)

	if health <= 0.0:
		game_over.emit()

func _eat_food(item: FoodItem) -> void:
	var restore := item.get_hunger_restore()
	hunger = clampf(hunger - restore, 0.0, 100.0)
	food_eaten.emit(restore)
	item.queue_free()

func _process(delta: float) -> void:
	if health <= 0.0:
		return
	_update_stats(delta)
	_update_invincibility(delta)

func _physics_process(_delta: float) -> void:
	if health <= 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	velocity = dir * move_speed
	move_and_slide()

	# Clamp to road bounds
	var pos := global_position
	pos.x = clampf(pos.x, asphalt_rect.position.x, asphalt_rect.position.x + asphalt_rect.size.x)
	pos.y = clampf(pos.y, asphalt_rect.position.y, asphalt_rect.position.y + asphalt_rect.size.y)
	global_position = pos

func _update_stats(delta: float) -> void:
	hunger = clampf(hunger + hunger_increase_per_second * delta, 0.0, 100.0)
	if hunger >= 100.0 - 0.001:
		health = clampf(health - health_drain_per_second_when_hungry_full * delta, 0.0, 100.0)
		if health <= 0.0:
			game_over.emit()

func _update_invincibility(delta: float) -> void:
	if not invincible:
		return
	_invincible_timer -= delta
	if _invincible_timer <= 0.0:
		invincible = false
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1)

func get_health_value() -> float:
	return health

func get_hunger_value() -> float:
	return hunger
