extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = -5.0  # Отрицательное значение для прыжка вверх
@export var gravity: float = 9.8

func _physics_process(delta):
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Получаем ввод
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Движение персонажа
	move_and_slide()
