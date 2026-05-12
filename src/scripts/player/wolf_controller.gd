extends CharacterBody2D

signal game_over
signal food_eaten(restore_amount: float, wildness_change: float)
signal grazing_triggered
signal chapter1_complete

# Movement — reduced for crippled old wolf
@export var move_speed: float = 160.0
@export var limp_intensity: float = 0.04

# Core stats
var health: float = 100.0
var hunger: float = 0.0
var muscle: float = 40.0
var wildness: float = 70.0

@export var hunger_increase_per_second: float = 4.0
@export var health_drain_per_second_when_hungry_full: float = 7.0

const DAMAGE_PER_HIT: float = 25.0
const GRAZE_DAMAGE: float = 25.0
const INVINCIBLE_DURATION: float = 0.5

var invincible: bool = false
var _invincible_timer: float = 0.0

# Chapter 1 grazing state
var total_food_eaten: float = 0.0
var grazing_threshold: float = 60.0
var _grazing_triggered: bool = false
var _grazing_active: bool = false
var _grazing_timer: float = 0.0
var _grazing_duration: float = 2.5

var _flash_blind_timer: float = 0.0
var asphalt_rect: Rect2

@onready var sprite := get_node_or_null("Sprite2D") as Sprite2D
var _hitbox_shape_size: Vector2 = Vector2(30, 24)
var _limp_accum: float = 0.0

func configure(p_asphalt_rect: Rect2, p_wolf_y: float, p_start_x: float, _p_end_x: float) -> void:
	asphalt_rect = p_asphalt_rect
	health = 100.0
	hunger = 0.0
	muscle = 40.0
	wildness = 70.0
	invincible = false
	total_food_eaten = 0.0
	_grazing_triggered = false
	_grazing_active = false
	global_position = Vector2(p_start_x, p_wolf_y)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0

	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	var hitbox_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = _hitbox_shape_size
	hitbox_shape.shape = shape
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)

	hitbox.collision_layer = 0
	hitbox.collision_mask = 0b11
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if _grazing_active:
		return
	if invincible:
		if _is_food(area):
			_eat_food(area)
		return
	if _is_vehicle(area):
		_handle_vehicle_hit(area)
	elif _is_food(area):
		_eat_food(area)

func _is_vehicle(node: Node) -> bool:
	return node.has_method("is_lethal")

func _is_food(node: Node) -> bool:
	return node.has_method("get_hunger_restore") and node.has_method("get_wildness_change")

func _handle_vehicle_hit(vehicle: Area2D) -> void:
	if total_food_eaten >= grazing_threshold and not _grazing_triggered and not vehicle.has_method("is_lethal"):
		if not vehicle.call("is_lethal"):
			_trigger_grazing()
			return

	if vehicle.has_method("is_lethal") and vehicle.call("is_lethal"):
		health = 0.0
		game_over.emit()
	else:
		_take_damage(DAMAGE_PER_HIT)

func _trigger_grazing() -> void:
	_grazing_triggered = true
	_grazing_active = true
	_grazing_timer = _grazing_duration
	_take_damage(GRAZE_DAMAGE)
	grazing_triggered.emit()
	var knockback := Vector2(randf_range(-200.0, -100.0), 80.0)
	velocity = knockback
	move_and_slide()

func _take_damage(amount: float) -> void:
	health = clampf(health - amount, 0.0, 100.0)
	invincible = true
	_invincible_timer = INVINCIBLE_DURATION
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.4)
	if health <= 0.0:
		game_over.emit()

func _eat_food(item: Area2D) -> void:
	var restore: float = float(item.call("get_hunger_restore"))
	var wild_change: float = float(item.call("get_wildness_change"))
	var muscle_change: float = float(item.call("get_muscle_change"))

	hunger = clampf(hunger - restore, 0.0, 100.0)
	wildness = clampf(wildness + wild_change, 0.0, 100.0)
	muscle = clampf(muscle + muscle_change, 0.0, 100.0)
	total_food_eaten += restore

	food_eaten.emit(restore, wild_change)
	item.queue_free()

func _process(delta: float) -> void:
	if health <= 0.0:
		return
	if _grazing_active:
		_grazing_timer -= delta
		if _grazing_timer <= 0.0:
			_grazing_active = false
			chapter1_complete.emit()
		return
	if _flash_blind_timer > 0.0:
		_flash_blind_timer -= delta
	_update_stats(delta)
	_update_invincibility(delta)

func get_effective_speed() -> float:
	var spd := move_speed
	if muscle < 20:  spd *= 0.60
	elif muscle < 40: spd *= 0.80
	return spd

func _physics_process(delta_f: float) -> void:
	if health <= 0.0 or _grazing_active:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
		move_and_slide()
		return

	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	var spd := get_effective_speed()
	velocity = dir * spd

	if dir.length() > 0.1:
		_limp_accum += delta_f
		velocity.x += sin(_limp_accum * 6.0) * limp_intensity * spd

	move_and_slide()
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

func apply_photo_flash(duration: float = 2.0) -> void:
	_flash_blind_timer = duration

func is_flash_blinded() -> bool:
	return _flash_blind_timer > 0.0

func get_health_value() -> float: return health
func get_hunger_value() -> float: return hunger
func get_muscle_value() -> float: return muscle
func get_wildness_value() -> float: return wildness
func get_total_food_eaten() -> float: return total_food_eaten
func get_chapter() -> int: return 1
