extends Button

@export var normal_color: Color = Color.WHITE
@export var highlighted_color: Color = Color.YELLOW

@onready var label: Label = $Label   # или другой дочерний узел с текстом

func _ready() -> void:
	label.modulate = normal_color
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered() -> void:
	label.modulate = highlighted_color

func _on_mouse_exited() -> void:
	label.modulate = normal_color
