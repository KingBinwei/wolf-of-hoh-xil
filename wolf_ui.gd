extends CanvasLayer

var _wolf: Node = null

@export var bar_width_px: float = 240.0
@export var bar_height_px: float = 12.0
@export var spacing_px: float = 6.0

@export var offset_left_px: float = 12.0
@export var offset_top_px: float = 12.0

@export var health_color: Color = Color(0.85, 0.15, 0.15, 1.0)
@export var hunger_color: Color = Color(0.90, 0.80, 0.15, 1.0)
@export var bg_color: Color = Color(0, 0, 0, 0.35)
@export var border_color: Color = Color(0, 0, 0, 0.6)

var _health_bg: ColorRect
var _health_fill: ColorRect
var _hunger_bg: ColorRect
var _hunger_fill: ColorRect

var _score_label: Label
var _game_over_overlay: ColorRect
var _game_over_label: Label
var _score_overlay_label: Label
var _restart_label: Label

var _game_over_shown: bool = false

const STAT_MIN := 0.0
const STAT_MAX := 100.0

func configure(wolf_node: Node) -> void:
	_wolf = wolf_node

func _ready() -> void:
	_build_ui()
	set_process(true)

func _build_ui() -> void:
	# Health bar background
	_health_bg = ColorRect.new()
	_health_bg.color = bg_color
	_health_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health_bg.anchor_right = 0
	_health_bg.anchor_bottom = 0
	_health_bg.position = Vector2(offset_left_px, offset_top_px)
	_health_bg.size = Vector2(bar_width_px, bar_height_px)

	# Health bar fill
	_health_fill = ColorRect.new()
	_health_fill.color = health_color
	_health_fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health_fill.anchor_right = 0
	_health_fill.anchor_bottom = 0
	_health_fill.position = _health_bg.position
	_health_fill.size = Vector2(bar_width_px, bar_height_px)

	# Hunger bar background
	_hunger_bg = ColorRect.new()
	_hunger_bg.color = bg_color
	_hunger_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hunger_bg.anchor_right = 0
	_hunger_bg.anchor_bottom = 0
	_hunger_bg.position = Vector2(offset_left_px, offset_top_px + bar_height_px + spacing_px)
	_hunger_bg.size = Vector2(bar_width_px, bar_height_px)

	# Hunger bar fill
	_hunger_fill = ColorRect.new()
	_hunger_fill.color = hunger_color
	_hunger_fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hunger_fill.anchor_right = 0
	_hunger_fill.anchor_bottom = 0
	_hunger_fill.position = _hunger_bg.position
	_hunger_fill.size = Vector2(bar_width_px, bar_height_px)

	# Borders for bars
	var health_border := ColorRect.new()
	health_border.color = border_color
	health_border.set_anchors_preset(Control.PRESET_TOP_LEFT)
	health_border.anchor_right = 0
	health_border.anchor_bottom = 0
	health_border.position = _health_bg.position
	health_border.size = Vector2(bar_width_px, bar_height_px)

	var hunger_border := ColorRect.new()
	hunger_border.color = border_color
	hunger_border.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hunger_border.anchor_right = 0
	hunger_border.anchor_bottom = 0
	hunger_border.position = _hunger_bg.position
	hunger_border.size = Vector2(bar_width_px, bar_height_px)

	# Score label (anchored top-right with small left offset)
	_score_label = Label.new()
	_score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_score_label.position = Vector2(-130, offset_top_px)
	_score_label.size = Vector2(120, 30)
	_score_label.text = "Food: 0"
	_score_label.add_theme_font_size_override("font_size", 20)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Game over overlay (hidden by default)
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
	_score_overlay_label.text = ""
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

	add_child(health_border)
	add_child(_health_bg)
	add_child(_health_fill)
	add_child(hunger_border)
	add_child(_hunger_bg)
	add_child(_hunger_fill)
	add_child(_score_label)
	add_child(_game_over_overlay)
	add_child(_game_over_label)
	add_child(_score_overlay_label)
	add_child(_restart_label)

func _process(_delta: float) -> void:
	if _wolf == null:
		return
	if not is_instance_valid(_wolf):
		return

	var health := 0.0
	var hunger := 0.0
	if _wolf.has_method("get_health_value"):
		health = float(_wolf.call("get_health_value"))
	else:
		health = float(_wolf.get("health"))

	if _wolf.has_method("get_hunger_value"):
		hunger = float(_wolf.call("get_hunger_value"))
	else:
		hunger = float(_wolf.get("hunger"))

	health = clampf(health, STAT_MIN, STAT_MAX)
	hunger = clampf(hunger, STAT_MIN, STAT_MAX)

	var health_ratio := (health - STAT_MIN) / (STAT_MAX - STAT_MIN)
	var hunger_ratio := (hunger - STAT_MIN) / (STAT_MAX - STAT_MIN)

	_health_fill.size.x = bar_width_px * health_ratio
	_hunger_fill.size.x = bar_width_px * hunger_ratio

func update_score(score: int) -> void:
	_score_label.text = "Food: %d" % score

func show_game_over(score: int) -> void:
	if _game_over_shown:
		return
	_game_over_shown = true

	_game_over_overlay.visible = true
	_game_over_label.visible = true
	_score_overlay_label.text = "Food Collected: %d" % score
	_score_overlay_label.visible = true
	_restart_label.visible = true
