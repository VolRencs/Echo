extends Node3D

@export var rotation_speed: float = 7.5  # Скорость в градусах/сек
static var shared_rotation_y: float = 4.0  # Статическая переменная для угла

func _ready():
	# Восстанавливаем угол при загрузке объекта
	rotation.y = shared_rotation_y

func _process(delta):
	# Вращение вокруг оси Y
	rotate_y(deg_to_rad(rotation_speed * delta))
	# Сохраняем текущий угол в статическую переменную
	shared_rotation_y = rotation.y
