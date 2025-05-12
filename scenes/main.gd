extends Node2D

@onready var popup_menu = $PopupMenu
@onready var graph_edit = $GraphEdit

# Store both name and path of each node
var node_tscn_map: Array[Dictionary] = []
var connections_map = []
var selected_nodes = {}
var stringname_to_node_map = {}

func _ready() -> void:
	var dir = DirAccess.open("res://scenes/Nodes")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var node_name = file_name.get_basename()  # Removes .tscn
				var full_path = "res://scenes/Nodes/" + file_name
				popup_menu.add_item(node_name.capitalize())
				node_tscn_map.append({
					"name": node_name,
					"path": full_path
				})
			file_name = dir.get_next()
		dir.list_dir_end()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("OpenMenu"):
		popup_menu.popup()
		popup_menu.position = get_global_mouse_position()

func _on_popup_menu_id_pressed(id: int) -> void:
	var node_data = node_tscn_map[id]
	print_debug("Loading: ", node_data["name"], " from ", node_data["path"])
	var scene = load(node_data["path"])
	if scene:
		var instance = scene.instantiate()
		graph_edit.add_child(instance)
		instance.global_position = get_global_mouse_position()
		stringname_to_node_map[instance.name] = instance

func execute_graph_bfs(start_node = null):
	var visited = {}
	var queue: Array[StringName] = []

	var incoming_count = {}
	for conn in connections_map:
		var to_node = conn[2]
		incoming_count[to_node] = incoming_count.get(to_node, 0) + 1

	var data_inputs: Dictionary = {}  # node_name -> { port: value }

	for node_name in stringname_to_node_map.keys():
		if incoming_count.get(node_name, 0) == 0:
			if start_node == null:
				queue.append(node_name)
				visited[node_name] = true
			data_inputs[node_name] = {}
	
	if start_node != null:
		queue.append(start_node)
		visited[start_node] = true

	while queue.size() > 0:
		var current_name = queue.pop_front()
		var current_node = stringname_to_node_map.get(current_name, null)
		if current_node == null:
			continue

		var input_data = data_inputs.get(current_name, {})
		var output_data = execute_node_logic(current_node, input_data)

		# Propagate output to connected nodes via ports
		for conn in connections_map:
			var from_node = conn[0]
			var from_port = conn[1]
			var to_node = conn[2]
			var to_port = conn[3]

			if from_node == current_name:
				if not data_inputs.has(to_node):
					data_inputs[to_node] = {}
				data_inputs[to_node][to_port] = output_data.get(from_port, null)

				incoming_count[to_node] -= 1
				if incoming_count[to_node] == 0 and not visited.has(to_node):
					queue.append(to_node)
					visited[to_node] = true


func execute_node_logic(node: PixflowNode, input_data: Dictionary) -> Dictionary:
	match node.node_type:
		"Load":
			return {0: node.image}  # Output port 0
		"Filter", "Invert", "Brightness":
			if input_data.has(0):  # Assuming input is connected at port 0
				var processed = node.update(input_data[0])
				return {0: processed}  # Output to port 0
		_:
			print("❓ Unknown node type: ", node.name)
	return {}

func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	get_node("GraphEdit").connect_node(from_node, from_port, to_node, to_port)
	connections_map.append([from_node, from_port, to_node, to_port])
	execute_graph_bfs()

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	get_node("GraphEdit").disconnect_node(from_node, from_port, to_node, to_port)
	var removal_index  = connections_map.find([from_node, from_port, to_node, to_port])
	connections_map.remove_at(removal_index)
	execute_graph_bfs()

func _on_graph_edit_node_selected(node: Node) -> void:
	selected_nodes[node] = true

func _on_graph_edit_node_deselected(node: Node) -> void:
	selected_nodes[node] = false

func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node in selected_nodes.keys():
		if selected_nodes[node]:
			node.queue_free()
	selected_nodes = {}
	
	# TODO: remove the connects associated with it too
