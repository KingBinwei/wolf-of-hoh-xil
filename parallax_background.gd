extends ParallaxBackground

# 暴露速度变量，方便你在检查器里随时调
@export var scroll_speed: float = 200.0

func _process(delta: float) -> void:
	# 错误写法：$ParallaxBackground.scroll_offset.y += ... (这会报 null 错)
	# 正确写法：因为脚本就在自己身上，直接写属性名字即可！
	scroll_offset.y += scroll_speed * delta
