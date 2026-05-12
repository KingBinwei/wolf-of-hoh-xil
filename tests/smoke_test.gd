extends SceneTree

var _scene: Node = null

func _initialize() -> void:
	print("=== SMOKE TEST ===")
	var packed := load("res://src/scenes/highway.tscn") as PackedScene
	if packed == null:
		print("FAIL: Could not load main scene")
		quit(1)
		return

	_scene = packed.instantiate()
	if _scene == null:
		print("FAIL: Could not instantiate main scene")
		quit(1)
		return

	root.add_child(_scene)
	print("PASS: Scene loaded — name=%s class=%s children=%d" % [_scene.name, _scene.get_class(), _scene.get_child_count()])

	# Wait one frame for _ready to fire, then quit
	create_timer(0.5).timeout.connect(_on_timer)

func _on_timer() -> void:
	print("PASS: Frame processed. No crash.")
	print("=== SMOKE TEST PASSED ===")
	quit(0)
