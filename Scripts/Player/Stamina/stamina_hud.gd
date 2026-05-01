extends Control

# ─── НАСТРОЙКИ ────────────────────────────────────────────────────────────────

@export var player_group: String = "Player"
@export var bar_path: NodePath = "StaminaBar"

# ─── УЗЛЫ ─────────────────────────────────────────────────────────────────────

@onready var _bar: StaminaBar = get_node(bar_path)

var _player: Node = null

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_find_player()
	if not _player:
		call_deferred("_find_player")

func _find_player() -> void:
	var members := get_tree().get_nodes_in_group(player_group)
	if members.is_empty():
		push_warning("StaminaHUD: игрок не найден в группе '%s'." % player_group)
		return
	_player = members[0]

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _player:
		return
	if not _player.has_method("get_stamina_normalized"):
		push_warning("StaminaHUD: у игрока нет метода get_stamina_normalized().")
		return
	_bar.value = _player.get_stamina_normalized()
