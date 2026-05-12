extends Node2D

# Road geometry
@export var asphalt_margin_x_ratio: float = 0.08
@export var asphalt_margin_y_ratio: float = 0.02
@export var road_fill_viewport_height_ratio: float = 1.0

# Food spawning
@export var food_spawn_interval_min: float = 4.0
@export var food_spawn_interval_max: float = 8.0
@export var max_food_on_road: int = 5
@export var wolf_y_band_half_px: float = 20.0

# Highway food types (indices matching FoodItem.FoodType enum)
const FOOD_TYPE_STARCH_SAUSAGE: int = 0
const FOOD_TYPE_COLD_BREAD: int = 1
const FOOD_TYPE_FRIED_STARCH: int = 2
const FOOD_TYPE_ROAST_CHICKEN: int = 3
const FOOD_TYPE_RAW_MEAT: int = 4
const HIGHWAY_FOOD_TYPES: Array = [0, 1, 2, 3, 4]

const FoodScript := preload("res://src/scripts/items/food.gd")

var _road_sprite: Sprite2D
var _road_rect_global: Rect2
var _asphalt_rect_global: Rect2

var _wolf: CharacterBody2D
var _spawner: Node
var _wolf_ui: CanvasLayer

var _food_spawn_timer: float = 0.0
var _next_food_spawn: float = 0.0
var _food_items: Array[Node] = []

var _game_over: bool = false
var _score: int = 0
var current_chapter: int = 1
var _chapter1_complete: bool = false
var _grazing_sequence_active: bool = false

func _ready() -> void:
	var parallax_bg := get_node("ParallaxBackground") as ParallaxBackground
	if parallax_bg != null:
		parallax_bg.scroll_speed = 0.0

	_road_sprite = get_node("ParallaxBackground/ParallaxLayer/Sprite2D") as Sprite2D
	_fit_road_sprite_to_viewport()
	_road_rect_global = _get_global_rect_for_sprite(_road_sprite)
	_asphalt_rect_global = Rect2(
		_road_rect_global.position.x + _road_rect_global.size.x * asphalt_margin_x_ratio,
		_road_rect_global.position.y + _road_rect_global.size.y * asphalt_margin_y_ratio,
		_road_rect_global.size.x * (1.0 - 2.0 * asphalt_margin_x_ratio),
		_road_rect_global.size.y * (1.0 - 2.0 * asphalt_margin_y_ratio)
	)

	_setup_camera()
	_spawn_world_nodes()
	_setup_geometry_dependent_configuration()
	_setup_food_spawning()
	_show_chapter_intro()

func _setup_food_spawning() -> void:
	_next_food_spawn = randf_range(food_spawn_interval_min, food_spawn_interval_max)

func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.enabled = true
	cam.position = _road_rect_global.position + _road_rect_global.size * 0.5
	add_child(cam)

func _spawn_world_nodes() -> void:
	_wolf = preload("res://src/scenes/wolf.tscn").instantiate() as CharacterBody2D
	_wolf.z_index = 10
	add_child(_wolf)

	_wolf_ui = preload("res://src/scripts/ui/wolf_ui.gd").new() as CanvasLayer
	_wolf_ui.name = "WolfUI"
	add_child(_wolf_ui)

	_spawner = preload("res://src/scripts/vehicles/vehicle_spawner.gd").new()
	_spawner.name = "VehicleSpawner"
	add_child(_spawner)

func _setup_geometry_dependent_configuration() -> void:
	var wolf_y := _asphalt_rect_global.position.y + _asphalt_rect_global.size.y * 0.5
	var wolf_start_x := _asphalt_rect_global.position.x
	var wolf_end_x := _asphalt_rect_global.position.x + _asphalt_rect_global.size.x

	wolf_node_configure(_wolf, _asphalt_rect_global, wolf_y, wolf_start_x, wolf_end_x)

	if _wolf.has_signal("game_over"):
		_wolf.game_over.connect(_on_wolf_game_over)
	if _wolf.has_signal("food_eaten"):
		_wolf.food_eaten.connect(_on_wolf_food_eaten)
	if _wolf.has_signal("grazing_triggered"):
		_wolf.grazing_triggered.connect(_on_grazing_triggered)
	if _wolf.has_signal("chapter1_complete"):
		_wolf.chapter1_complete.connect(_on_chapter1_complete)

	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("configure", _wolf)

	_spawner.configure(_asphalt_rect_global, wolf_y, wolf_y_band_half_px, 1.0)
	if _spawner.has_method("set_wolf_reference"):
		_spawner.set_wolf_reference(_wolf)
	if _spawner.has_signal("food_thrown_by_vehicle"):
		_spawner.food_thrown_by_vehicle.connect(_on_vehicle_threw_food)
	if _spawner.has_signal("vehicle_photo_flash"):
		_spawner.vehicle_photo_flash.connect(_on_vehicle_photo_flash)

	_spawner.start_spawning()

func _show_chapter_intro() -> void:
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("show_chapter_title", "第一章", "十二米宽的沥青")

func _process(delta: float) -> void:
	if _game_over:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return
	if _grazing_sequence_active:
		return
	_food_spawn_timer += delta
	if _food_spawn_timer >= _next_food_spawn:
		_food_spawn_timer = 0.0
		_next_food_spawn = randf_range(food_spawn_interval_min, food_spawn_interval_max)
		_spawn_food()

func _spawn_food() -> void:
	_food_items = _food_items.filter(func(f): return is_instance_valid(f))
	if _food_items.size() >= max_food_on_road:
		return

	var food: Area2D = FoodScript.new()
	var ftype: int = HIGHWAY_FOOD_TYPES[randi() % HIGHWAY_FOOD_TYPES.size()]

	var road_left := _asphalt_rect_global.position.x + 20.0
	var road_right := _asphalt_rect_global.position.x + _asphalt_rect_global.size.x - 20.0
	var road_top := _asphalt_rect_global.position.y + 20.0
	var road_bottom := _asphalt_rect_global.position.y + _asphalt_rect_global.size.y - 20.0

	food.call("configure", ftype, Vector2(
		randf_range(road_left, road_right),
		randf_range(road_top, road_bottom)
	))
	food.z_index = 3
	food.tree_exited.connect(_on_food_removed.bind(food))
	add_child(food)
	_food_items.append(food)

func _on_food_removed(food: Node) -> void:
	_food_items.erase(food)

func _on_vehicle_threw_food(food_type: int, position: Vector2) -> void:
	_food_items = _food_items.filter(func(f): return is_instance_valid(f))
	if _food_items.size() >= max_food_on_road + 2:
		return

	var food: Area2D = FoodScript.new()
	food.call("configure", food_type, position)
	food.z_index = 3
	food.tree_exited.connect(_on_food_removed.bind(food))
	add_child(food)
	_food_items.append(food)

func _on_vehicle_photo_flash(_pos: Vector2) -> void:
	if is_instance_valid(_wolf) and _wolf.has_method("apply_photo_flash"):
		_wolf.apply_photo_flash(2.0)
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("show_flash_overlay")

func _on_wolf_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("show_game_over", _score)
	if is_instance_valid(_spawner):
		_spawner.set_process(false)

func _on_wolf_food_eaten(_restore_amount: float, _wildness_change: float) -> void:
	_score += 1
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("update_score", _score)

func _on_grazing_triggered() -> void:
	_grazing_sequence_active = true
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("show_grazing_event")

func _on_chapter1_complete() -> void:
	_chapter1_complete = true
	_grazing_sequence_active = false
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("show_chapter_end", "第一章 结束", "荒野在远处等待着。")

func wolf_node_configure(wolf_node: Node, asphalt_rect: Rect2, wolf_y: float, start_x: float, end_x: float) -> void:
	wolf_node.call("configure", asphalt_rect, wolf_y, start_x, end_x)

func _get_global_rect_for_sprite(sprite: Sprite2D) -> Rect2:
	var local_rect: Rect2 = sprite.get_rect()
	var p1 := sprite.to_global(local_rect.position)
	var p2 := sprite.to_global(local_rect.position + local_rect.size)
	return Rect2(
		Vector2(min(p1.x, p2.x), min(p1.y, p2.y)),
		Vector2(abs(p2.x - p1.x), abs(p2.y - p1.y))
	)

func _fit_road_sprite_to_viewport() -> void:
	if _road_sprite == null or _road_sprite.texture == null:
		return
	var tex_size: Vector2 = _road_sprite.texture.get_size()
	if tex_size.y <= 0.001:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var target_h: float = viewport_size.y * road_fill_viewport_height_ratio
	var uniform_scale: float = target_h / tex_size.y
	_road_sprite.scale = Vector2(uniform_scale, uniform_scale)
