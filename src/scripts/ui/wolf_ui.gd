extends CanvasLayer

var _wolf: Node = null

@export var bar_width_px: float = 200.0
@export var bar_height_px: float = 10.0
@export var spacing_px: float = 4.0
@export var offset_left_px: float = 10.0
@export var offset_top_px: float = 10.0

@export var health_color: Color = Color(0.85, 0.15, 0.15, 1.0)
@export var hunger_color: Color = Color(0.90, 0.80, 0.15, 1.0)
@export var wildness_color: Color = Color(0.30, 0.70, 0.85, 1.0)
@export var muscle_color: Color = Color(0.70, 0.50, 0.20, 1.0)
@export var bg_color: Color = Color(0, 0, 0, 0.35)
@export var border_color: Color = Color(0, 0, 0, 0.6)

var _health_bg: ColorRect
var _health_fill: ColorRect
var _hunger_bg: ColorRect
var _hunger_fill: ColorRect
var _wildness_bg: ColorRect
var _wildness_fill: ColorRect
var _muscle_bg: ColorRect
var _muscle_fill: ColorRect

var _score_label: Label
var _chapter_label: Label

var _game_over_overlay: ColorRect
var _game_over_label: Label
var _score_overlay_label: Label
var _restart_label: Label

var _flash_overlay: ColorRect
var _chapter_title_label: Label
var _chapter_subtitle_label: Label
var _chapter_end_label: Label

var _game_over_shown: bool = false

const STAT_MIN := 0.0
const STAT_MAX := 100.0

func configure(wolf_node: Node) -> void:
	_wolf = wolf_node

func _ready() -> void:
	_build_ui()
	set_process(true)

func _build_ui() -> void:
	# Health bar
	_health_bg = _make_bar_bg(0)
	_health_fill = _make_bar_fill(0, health_color)
	# Hunger bar
	_hunger_bg = _make_bar_bg(1)
	_hunger_fill = _make_bar_fill(1, hunger_color)
	# Wildness bar
	_wildness_bg = _make_bar_bg(2)
	_wildness_fill = _make_bar_fill(2, wildness_color)
	# Muscle bar
	_muscle_bg = _make_bar_bg(3)
	_muscle_fill = _make_bar_fill(3, muscle_color)

	# Borders
	for i in range(4):
		var border := ColorRect.new()
		border.color = border_color
		border.set_anchors_preset(Control.PRESET_TOP_LEFT)
		border.anchor_right = 0; border.anchor_bottom = 0
		var y_off := offset_top_px + i * (bar_height_px + spacing_px)
		border.position = Vector2(offset_left_px, y_off)
		border.size = Vector2(bar_width_px, bar_height_px)
		# Draw as 1px outline only
		border.color = border_color
		add_child(border)

	add_child(_health_bg); add_child(_health_fill)
	add_child(_hunger_bg); add_child(_hunger_fill)
	add_child(_wildness_bg); add_child(_wildness_fill)
	add_child(_muscle_bg); add_child(_muscle_fill)

	# Score label
	_score_label = Label.new()
	_score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_score_label.position = Vector2(-140, offset_top_px)
	_score_label.size = Vector2(130, 24)
	_score_label.text = "Food: 0"
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_score_label)

	# Chapter indicator
	_chapter_label = Label.new()
	_chapter_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_chapter_label.position = Vector2(-140, offset_top_px + 22)
	_chapter_label.size = Vector2(130, 20)
	_chapter_label.text = "Ch.1 公路"
	_chapter_label.add_theme_font_size_override("font_size", 14)
	_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chapter_label.modulate = Color(1, 1, 1, 0.5)
	add_child(_chapter_label)

	# Chapter title (large, centered, temporary)
	_chapter_title_label = Label.new()
	_chapter_title_label.set_anchors_preset(Control.PRESET_CENTER)
	_chapter_title_label.position = Vector2(0, -100)
	_chapter_title_label.size = Vector2(400, 60)
	_chapter_title_label.add_theme_font_size_override("font_size", 42)
	_chapter_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_title_label.visible = false
	add_child(_chapter_title_label)

	_chapter_subtitle_label = Label.new()
	_chapter_subtitle_label.set_anchors_preset(Control.PRESET_CENTER)
	_chapter_subtitle_label.position = Vector2(0, -40)
	_chapter_subtitle_label.size = Vector2(400, 40)
	_chapter_subtitle_label.add_theme_font_size_override("font_size", 22)
	_chapter_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_subtitle_label.modulate = Color(1, 1, 1, 0.7)
	_chapter_subtitle_label.visible = false
	add_child(_chapter_subtitle_label)

	# Chapter end label
	_chapter_end_label = Label.new()
	_chapter_end_label.set_anchors_preset(Control.PRESET_CENTER)
	_chapter_end_label.position = Vector2(0, 40)
	_chapter_end_label.size = Vector2(400, 30)
	_chapter_end_label.add_theme_font_size_override("font_size", 18)
	_chapter_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_end_label.visible = false
	add_child(_chapter_end_label)

	# Flash overlay (photo flash blinding effect)
	_flash_overlay = ColorRect.new()
	_flash_overlay.color = Color(1, 1, 1, 0.0)
	_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_overlay)

	# Game over overlay
	_game_over_overlay = ColorRect.new()
	_game_over_overlay.color = Color(0, 0, 0, 0.7)
	_game_over_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_overlay.visible = false

	_game_over_label = Label.new()
	_game_over_label.set_anchors_preset(Control.PRESET_CENTER)
	_game_over_label.position = Vector2(0, -60)
	_game_over_label.size = Vector2(300, 60)
	_game_over_label.text = "GAME OVER"
	_game_over_label.add_theme_font_size_override("font_size", 48)
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.visible = false

	_score_overlay_label = Label.new()
	_score_overlay_label.set_anchors_preset(Control.PRESET_CENTER)
	_score_overlay_label.position = Vector2(0, 10)
	_score_overlay_label.size = Vector2(300, 40)
	_score_overlay_label.add_theme_font_size_override("font_size", 28)
	_score_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_overlay_label.visible = false

	_restart_label = Label.new()
	_restart_label.set_anchors_preset(Control.PRESET_CENTER)
	_restart_label.position = Vector2(0, 60)
	_restart_label.size = Vector2(300, 30)
	_restart_label.text = "Press R to Restart"
	_restart_label.add_theme_font_size_override("font_size", 20)
	_restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_restart_label.modulate = Color(1, 1, 1, 0.8)
	_restart_label.visible = false

	add_child(_game_over_overlay)
	add_child(_game_over_label)
	add_child(_score_overlay_label)
	add_child(_restart_label)

func _make_bar_bg(index: int) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = bg_color
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.anchor_right = 0; bar.anchor_bottom = 0
	bar.position = Vector2(offset_left_px, offset_top_px + index * (bar_height_px + spacing_px))
	bar.size = Vector2(bar_width_px, bar_height_px)
	return bar

func _make_bar_fill(index: int, color: Color) -> ColorRect:
	var fill := ColorRect.new()
	fill.color = color
	fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fill.anchor_right = 0; fill.anchor_bottom = 0
	fill.position = Vector2(offset_left_px, offset_top_px + index * (bar_height_px + spacing_px))
	fill.size = Vector2(bar_width_px, bar_height_px)
	return fill

func _process(_delta: float) -> void:
	if _wolf == null or not is_instance_valid(_wolf):
		return

	var health := _get_stat("health")
	var hunger := _get_stat("hunger")
	var wildness_val := _get_stat("wildness")
	var muscle_val := _get_stat("muscle")

	health = clampf(health, STAT_MIN, STAT_MAX)
	hunger = clampf(hunger, STAT_MIN, STAT_MAX)
	wildness_val = clampf(wildness_val, STAT_MIN, STAT_MAX)
	muscle_val = clampf(muscle_val, STAT_MIN, STAT_MAX)

	var ratio: float = 1.0 / (STAT_MAX - STAT_MIN)
	_health_fill.size.x = bar_width_px * health * ratio
	_hunger_fill.size.x = bar_width_px * hunger * ratio
	_wildness_fill.size.x = bar_width_px * wildness_val * ratio
	_muscle_fill.size.x = bar_width_px * muscle_val * ratio

	# Flash overlay fade
	if _flash_overlay.color.a > 0.0:
		_flash_overlay.color.a = move_toward(_flash_overlay.color.a, 0.0, _delta * 2.0)

	# Chapter title fade
	if _chapter_title_label.visible:
		_chapter_title_label.modulate.a = move_toward(_chapter_title_label.modulate.a, 0.0, _delta * 0.3)

func _get_stat(name: String) -> float:
	var method_name := "get_%s_value" % name
	if _wolf.has_method(method_name):
		return float(_wolf.call(method_name))
	return float(_wolf.get(name))

func update_score(score: int) -> void:
	_score_label.text = "Food: %d" % score

func show_chapter_title(title: String, subtitle: String) -> void:
	_chapter_title_label.text = title
	_chapter_subtitle_label.text = subtitle
	_chapter_title_label.modulate = Color(1, 1, 1, 1)
	_chapter_subtitle_label.modulate = Color(1, 1, 1, 0.7)
	_chapter_title_label.visible = true
	_chapter_subtitle_label.visible = true
	# Auto-fade via _process

func show_chapter_end(title: String, subtitle: String) -> void:
	_chapter_end_label.text = subtitle
	_chapter_end_label.visible = true
	_chapter_title_label.text = title
	_chapter_title_label.modulate = Color(1, 1, 1, 1)
	_chapter_title_label.visible = true
	_chapter_subtitle_label.visible = false

func show_flash_overlay() -> void:
	_flash_overlay.color.a = 0.7

func show_grazing_event() -> void:
	_chapter_title_label.text = ""
	_chapter_subtitle_label.text = "被车身擦过..."
	_chapter_subtitle_label.modulate = Color(1, 0.8, 0.3, 0.9)
	_chapter_subtitle_label.visible = true
	_chapter_title_label.visible = false

func show_game_over(score: int) -> void:
	if _game_over_shown:
		return
	_game_over_shown = true
	_game_over_overlay.visible = true
	_game_over_label.visible = true
	_score_overlay_label.text = "Food Collected: %d" % score
	_score_overlay_label.visible = true
	_restart_label.visible = true
