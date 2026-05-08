extends Node2D

@export var asphalt_margin_x_ratio: float = 0.08
@export var asphalt_margin_y_ratio: float = 0.02
@export var road_fill_viewport_height_ratio: float = 1.0

@export var ranger_outside_offset_x_ratio: float = 0.08
@export var ranger_vertical_offset_px: float = 130.0
@export var ranger_cone_range_ratio: float = 0.72
@export var ranger_cone_tilt_deg: float = 14.0
@export var ranger_cone_color: Color = Color(0.95, 0.2, 0.2, 0.12)

@export var food_spawn_interval_min: float = 2.5
@export var food_spawn_interval_max: float = 6.0
@export var max_food_on_road: int = 5

@export var wolf_y_band_half_px: float = 20.0

var _road_sprite: Sprite2D
var _road_rect_global: Rect2
var _asphalt_rect_global: Rect2

var _wolf: CharacterBody2D
var _ranger: Node2D
var _spawner: Node
var _wolf_ui: CanvasLayer

var _food_spawn_timer: float = 0.0
var _next_food_spawn: float = 0.0
var _food_items: Array[Node] = []

var _game_over: bool = false
var _score: int = 0

func _ready() -> void:
	# Stop background scrolling; vehicles + wolf movement provide the gameplay motion.
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

func _setup_food_spawning() -> void:
	_next_food_spawn = randf_range(food_spawn_interval_min, food_spawn_interval_max)

func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.enabled = true
	cam.position = _road_rect_global.position + _road_rect_global.size * 0.5
	add_child(cam)

func _spawn_world_nodes() -> void:
	_wolf = preload("res://wolf.tscn").instantiate() as CharacterBody2D
	_wolf.z_index = 10
	add_child(_wolf)

	_wolf_ui = preload("res://wolf_ui.gd").new() as CanvasLayer
	_wolf_ui.name = "WolfUI"
	add_child(_wolf_ui)

	_ranger = preload("res://ranger_vision.gd").new()
	_ranger.name = "Ranger"
	_ranger.z_index = 4
	add_child(_ranger)

	_spawner = preload("res://vehicle_spawner.gd").new()
	_spawner.name = "VehicleSpawner"
	add_child(_spawner)

func _setup_geometry_dependent_configuration() -> void:
	var wolf_y := _asphalt_rect_global.position.y + _asphalt_rect_global.size.y * 0.5
	var wolf_start_x := _asphalt_rect_global.position.x
	var wolf_end_x := _asphalt_rect_global.position.x + _asphalt_rect_global.size.x

	# Configure wolf.
	wolf_node_configure(_wolf, _asphalt_rect_global, wolf_y, wolf_start_x, wolf_end_x)

	# Connect wolf signals.
	if _wolf.has_signal("game_over"):
		_wolf.game_over.connect(_on_wolf_game_over)
	if _wolf.has_signal("food_eaten"):
		_wolf.food_eaten.connect(_on_wolf_food_eaten)

	# Configure UI.
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("configure", _wolf)

	# Configure ranger on the LEFT side of the road.
	var ranger_x := _asphalt_rect_global.position.x - _asphalt_rect_global.size.x * ranger_outside_offset_x_ratio
	var ranger_y := wolf_y
	ranger_y = clampf(
		ranger_y,
		_asphalt_rect_global.position.y + 24.0,
		_asphalt_rect_global.position.y + _asphalt_rect_global.size.y - 24.0
	)
	_ranger.global_position = Vector2(ranger_x, ranger_y)
	ranger_configure(_ranger, _asphalt_rect_global, ranger_x, wolf_y)

	# Configure spawner.
	_spawner.configure(
		_asphalt_rect_global,
		wolf_y,
		wolf_y_band_half_px,
		1.0
	)
	_spawner.start_spawning()

func _process(delta: float) -> void:
	if _game_over:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	# Food spawning timer.
	_food_spawn_timer += delta
	if _food_spawn_timer >= _next_food_spawn:
		_food_spawn_timer = 0.0
		_next_food_spawn = randf_range(food_spawn_interval_min, food_spawn_interval_max)
		_spawn_food()

func _spawn_food() -> void:
	# Clean up freed entries.
	_food_items = _food_items.filter(func(f): return is_instance_valid(f))
	if _food_items.size() >= max_food_on_road:
		return

	var food := preload("res://food.gd").new()
	var types := [
		FoodItem.FoodType.BURGER,
		FoodItem.FoodType.EGG_TART,
		FoodItem.FoodType.BONE,
		FoodItem.FoodType.FISH
	]
	var ftype: FoodItem.FoodType = types[randi() % types.size()]

	# Random position on the road surface.
	var road_left := _asphalt_rect_global.position.x + 20.0
	var road_right := _asphalt_rect_global.position.x + _asphalt_rect_global.size.x - 20.0
	var road_top := _asphalt_rect_global.position.y + 20.0
	var road_bottom := _asphalt_rect_global.position.y + _asphalt_rect_global.size.y - 20.0

	food.configure(ftype, Vector2(
		randf_range(road_left, road_right),
		randf_range(road_top, road_bottom)
	))
	food.z_index = 3
	food.tree_exited.connect(_on_food_removed.bind(food))
	add_child(food)
	_food_items.append(food)

func _on_food_removed(food: Node) -> void:
	_food_items.erase(food)

func _on_wolf_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("show_game_over", _score)
	# Stop the spawner.
	if is_instance_valid(_spawner):
		_spawner.set_process(false)

func _on_wolf_food_eaten(_restore_amount: float) -> void:
	_score += 1
	if is_instance_valid(_wolf_ui):
		_wolf_ui.call("update_score", _score)

func wolf_node_configure(wolf_node: Node, asphalt_rect: Rect2, wolf_y: float, start_x: float, end_x: float) -> void:
	(wolf_node as Node).call("configure", asphalt_rect, wolf_y, start_x, end_x)

func ranger_configure(ranger_node: Node2D, asphalt_rect: Rect2, ranger_x: float, wolf_y: float) -> void:
	var cone_range_px: float = asphalt_rect.size.x * ranger_cone_range_ratio
	var cone_dir: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(ranger_cone_tilt_deg))
	ranger_node.call("configure", _wolf, asphalt_rect, cone_range_px, get_viewport_rect().size, cone_dir)
	ranger_node.set("cone_color", ranger_cone_color)
	# Ranger detection = game over.
	if ranger_node.has_signal("wolf_detected"):
		ranger_node.wolf_detected.connect(_on_wolf_game_over)

func _get_global_rect_for_sprite(sprite: Sprite2D) -> Rect2:
	var local_rect: Rect2 = sprite.get_rect()
	var p1 := sprite.to_global(local_rect.position)
	var p2 := sprite.to_global(local_rect.position + local_rect.size)
	return Rect2(
		Vector2(min(p1.x, p2.x), min(p1.y, p2.y)),
		Vector2(abs(p2.x - p1.x), abs(p2.y - p1.y))
	)

func _fit_road_sprite_to_viewport() -> void:
	if _road_sprite == null:
		return
	if _road_sprite.texture == null:
		return

	var tex_size: Vector2 = _road_sprite.texture.get_size()
	if tex_size.y <= 0.001:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var target_h: float = viewport_size.y * road_fill_viewport_height_ratio
	var uniform_scale: float = target_h / tex_size.y
	_road_sprite.scale = Vector2(uniform_scale, uniform_scale)
