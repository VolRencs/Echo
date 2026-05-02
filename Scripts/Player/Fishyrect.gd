extends ColorRect

## Автоматически держит aspect_ratio шейдера актуальным при любом разрешении.
## Прикрепи этот скрипт на ColorRect с шейдером fisheye.gdshader.

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_resized)
	_update_aspect()

func _on_viewport_resized() -> void:
	_update_aspect()

func _update_aspect() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.y > 0.0:
		material.set_shader_parameter("aspect_ratio", viewport_size.x / viewport_size.y)
