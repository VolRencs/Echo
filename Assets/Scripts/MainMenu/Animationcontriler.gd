extends Node

@export var main_menu_panel: Node

# Вызывается, например, из AnimationPlayer -> Call Method Track
func show_main_menu() -> void:
	if main_menu_panel:
		main_menu_panel.visible = true
