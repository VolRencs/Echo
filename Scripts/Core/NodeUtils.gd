extends RefCounted
class_name NodeUtils

static func find_first_in_group_by_name(
	tree: SceneTree,
	group_name: StringName,
	node_name: StringName
) -> Node:
	for node: Node in tree.get_nodes_in_group(group_name):
		if node.name == node_name:
			return node
	return null

static func find_audio_stream_player(tree: SceneTree, node_name: StringName) -> AudioStreamPlayer:
	return find_first_in_group_by_name(tree, &"Sound", node_name) as AudioStreamPlayer

static func collect_descendants_in_group(root: Node, group_name: StringName) -> Array[Node]:
	var nodes: Array[Node] = []
	_collect_descendants_in_group(root, group_name, nodes)
	return nodes

static func _collect_descendants_in_group(
	root: Node,
	group_name: StringName,
	nodes: Array[Node]
) -> void:
	for child: Node in root.get_children():
		if child.is_in_group(group_name):
			nodes.append(child)
		_collect_descendants_in_group(child, group_name, nodes)
