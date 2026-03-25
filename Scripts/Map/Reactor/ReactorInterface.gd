extends Node3D

var is_mouse_inside := false
var is_interface_open := false

var last_event_pos2D := Vector2.ZERO
var has_last_event_pos2D := false
var last_event_time := -1.0

@onready var node_viewport: SubViewport = $Interface/SubViewport
@onready var node_quad: MeshInstance3D = $Interface/Quad
@onready var node_area: Area3D = $Interface/Quad/Area3D
@onready var trigger: Area3D = $Triger
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _quad_mesh_size := Vector2.ONE

func _ready() -> void:
	var quad_mesh := node_quad.mesh as QuadMesh
	if quad_mesh:
		_quad_mesh_size = quad_mesh.size
	else:
		push_warning("ReactorInterface: Quad mesh is missing or has an unexpected type")

	node_area.mouse_entered.connect(_mouse_entered_area)
	node_area.mouse_exited.connect(_mouse_exited_area)
	node_area.input_event.connect(_mouse_input_event)
	close_interface()
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body and body.is_in_group("Player") and not is_interface_open:
		open_interface()

func _on_body_exited(body: Node3D) -> void:
	if body and body.is_in_group("Player") and is_interface_open:
		close_interface()

func open_interface() -> void:
	is_interface_open = true
	animation_player.play("Open_Reactor_Interface")

func close_interface() -> void:
	is_interface_open = false
	animation_player.play("Close_Reactor_Interface")

func Open_Interface() -> void:
	open_interface()

func Close_Interface() -> void:
	close_interface()

func _mouse_entered_area() -> void:
	is_mouse_inside = true

func _mouse_exited_area() -> void:
	is_mouse_inside = false

func _unhandled_input(event: InputEvent) -> void:
	# Check if the event is a non-mouse/non-touch event
	if _is_pointer_event(event):
		# If the event is a mouse/touch event, then we can ignore it here, because it will be
		# handled via Physics Picking.
		return
	node_viewport.push_input(event)

func _mouse_input_event(
	_camera: Camera3D,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	# Event position in Area3D in world coordinate space.
	var event_pos3D := event_position

	# Current time in seconds since engine start.
	var now: float = Time.get_ticks_msec() / 1000.0

	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = node_quad.global_transform.affine_inverse() * event_pos3D

	# TODO: Adapt to bilboard mode or avoid completely.

	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / _quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / _quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5

		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport.size.x
		event_pos2D.y *= node_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.

	elif has_last_event_pos2D:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D

	_apply_event_position(event, event_pos2D)
	_apply_event_motion(event, event_pos2D, now)

	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D
	has_last_event_pos2D = true

	# Update last_event_time to current time.
	last_event_time = now

	# Finally, send the processed input event to the viewport.
	node_viewport.push_input(event)

func _apply_event_position(event: InputEvent, event_pos2D: Vector2) -> void:
	if event is InputEventMouse:
		var mouse_event := event as InputEventMouse
		mouse_event.position = event_pos2D
		mouse_event.global_position = event_pos2D
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		touch_event.position = event_pos2D
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		drag_event.position = event_pos2D

func _apply_event_motion(event: InputEvent, event_pos2D: Vector2, now: float) -> void:
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if not has_last_event_pos2D:
			mouse_motion.relative = Vector2.ZERO
			mouse_motion.velocity = Vector2.ZERO
		else:
			mouse_motion.relative = event_pos2D - last_event_pos2D
			var mouse_delta_time := maxf(now - last_event_time, 0.000001)
			mouse_motion.velocity = mouse_motion.relative / mouse_delta_time
	elif event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		if not has_last_event_pos2D:
			screen_drag.relative = Vector2.ZERO
			screen_drag.velocity = Vector2.ZERO
		else:
			screen_drag.relative = event_pos2D - last_event_pos2D
			var drag_delta_time := maxf(now - last_event_time, 0.000001)
			screen_drag.velocity = screen_drag.relative / drag_delta_time

func _is_pointer_event(event: InputEvent) -> bool:
	return (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenDrag
		or event is InputEventScreenTouch
	)
