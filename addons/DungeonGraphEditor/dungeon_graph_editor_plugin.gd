@tool
extends EditorPlugin

const GraphEditWindow = preload("dungeon_graph_editor.tscn")

var _dock: Control
var _graph_edit: GraphEdit
var _current_graph_data: DungeonGraphData
var room_node: PackedScene = preload("room_node.tscn")
var toolbar: HBoxContainer
var new_button: Button
var load_button: Button
var save_button: Button
var add_room_button: MenuButton

func _enter_tree():
	# make the dock
	_dock = Control.new()
	_dock.name = "Graph Editor"
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)
	var window = GraphEditWindow.instantiate()
	_dock.add_child(window)

	_graph_edit = window.get_node("VBoxContainer/GraphEdit")
	toolbar = _graph_edit.get_menu_hbox()

	new_button = Button.new()
	new_button.text = "New"
	toolbar.add_child(new_button)

	load_button = Button.new()
	load_button.text = "Load"
	toolbar.add_child(load_button)

	save_button = Button.new()
	save_button.text = "Save"
	toolbar.add_child(save_button)

	add_room_button = MenuButton.new()
	add_room_button.text = "Add Room"
	toolbar.add_child(add_room_button)

	_graph_edit.connect("connection_request", Callable(self, "_on_connection_request"))
	_graph_edit.connect("disconnection_request", Callable(self, "_on_disconnection_request"))
	_graph_edit.connect("delete_nodes_request", Callable(self, "_on_delete_nodes_request"))
	_graph_edit.connect("node_selected", Callable(self, "_on_node_selected"))

	new_button.connect("pressed", Callable(self, "_on_new_button_pressed"))
	load_button.connect("pressed", Callable(self, "_on_load_button_pressed"))
	save_button.connect("pressed", Callable(self, "_on_save_button_pressed"))

	var popup = add_room_button.get_popup()
	for type in RoomTypes.RoomType.keys():
		popup.add_item(type, RoomTypes.RoomType[type])
	popup.connect("id_pressed", Callable(self, "_on_add_room_button_pressed"))
	
	# Reset zoom and scroll (optional, but can help with consistency)
	_graph_edit.zoom = 1.0
	_graph_edit.set_scroll_offset(Vector2(0, 0))

func _exit_tree():
	if is_instance_valid(_dock):
		_dock.queue_free()

# --- Graph Data Management ---

func create_new_graph_data():
	_current_graph_data = DungeonGraphData.new()
	_current_graph_data.room_type_scenes = {}
	update_graph_edit()

func load_graph_data(path: String):
	var loaded_data = load(path)
	if loaded_data is DungeonGraphData:
		_current_graph_data = loaded_data
		update_graph_edit()
	else:
		push_error("Failed to load DungeonGraphData from: ", path)
		print("Failed to load DungeonGraphData from: ", path) # Added for extra debugging.

func save_graph_data(path: String):
	if _current_graph_data:
		var err = ResourceSaver.save(_current_graph_data, path)
		if err != OK:
			push_error("Failed to save DungeonGraphData to: ", path)
			print("Failed to save DungeonGraphData to: ", path, " Error: ", err) # Added for extra debugging.

		else:
			print("Saved")

# --- UI Callbacks ---

func _on_new_button_pressed():
	create_new_graph_data()

func _on_load_button_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.tres ; Godot Resource Files")
	file_dialog.connect("file_selected", Callable(self, "_on_load_file_selected")) # Changed callback
	get_tree().get_root().add_child(file_dialog)
	file_dialog.popup_centered()  # Make the dialog appear.

func _on_load_file_selected(path: String): # Dedicated callback for loading
	load_graph_data(path)
	
func _on_save_button_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.tres ; Godot Resource Files")
	file_dialog.connect("file_selected", Callable(self, "_on_save_file_selected")) # Changed callback
	get_tree().get_root().add_child(file_dialog)
	file_dialog.popup_centered() # Make the dialog appear.

func _on_save_file_selected(path: String): # Dedicated callback for saving
	save_graph_data(path)
	

# Helper function to calculate the centered position
func _get_centered_graph_position() -> Vector2:
	var scroll_offset = _graph_edit.get_scroll_offset()

	# Calculate the center in the GraphEdit's coordinate space
	var center = (scroll_offset / 2)

	return Vector2(round(center.x), round(center.y))

func _on_add_room_button_pressed(type_index: int):
	if _current_graph_data:
		var node_id = str(_current_graph_data.next_node_id)
		_current_graph_data.next_node_id += 1

		# Use the helper function to get the centered position
		var center_position = _get_centered_graph_position()
		
		var node_data = {
			"type": type_index,
			"position": center_position,
			"connections": []
		}
		_current_graph_data.graph_nodes[node_id] = node_data

		var graph_node = room_node.instantiate()
		graph_node.name = node_id
		graph_node.title = str(RoomTypes.RoomType.find_key(type_index))
		graph_node.position_offset = center_position
		_graph_edit.add_child(graph_node)
	else:
		push_warning("No graph data loaded. Create or load a graph first.")

# --- GraphEdit Callbacks ---

func _on_connection_request(from_node_name, from_slot, to_node_name, to_slot):
	if _current_graph_data:
		var from_id = str(from_node_name)
		var to_id = str(to_node_name)

		if from_id in _current_graph_data.graph_nodes and to_id in _current_graph_data.graph_nodes:
			if not _current_graph_data.graph_nodes[from_id]["connections"].has(to_id):
				_current_graph_data.graph_nodes[from_id]["connections"].append(to_id)
				_graph_edit.connect_node(from_id, from_slot, to_id, to_slot)
		else:
			push_warning("Invalid node connection request.")

func _on_disconnection_request(from_node_name, from_slot, to_node_name, to_slot):
	if _current_graph_data:
		var from_id = str(from_node_name)
		var to_id = str(to_node_name)

		if from_id in _current_graph_data.graph_nodes and to_id in _current_graph_data.graph_nodes:
			if _current_graph_data.graph_nodes[from_id]["connections"].has(to_id):
				_current_graph_data.graph_nodes[from_id]["connections"].erase(to_id)
				_graph_edit.disconnect_node(from_id, from_slot, to_id, to_slot)
		else:
			push_warning("Invalid node disconnection request.")

func _on_node_selected(node):
	pass

func _on_delete_nodes_request(nodes):
	if _current_graph_data:
		for node_name in nodes:
			var node_id = str(node_name)

			# Disconnect in GraphEdit and data simultaneously
			if node_id in _current_graph_data.graph_nodes:
				for connection in _graph_edit.get_connection_list():
					if connection.from_node == node_id or connection.to_node == node_id:
						_graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)

				# Remove connections in data
				for other_node_id in _current_graph_data.graph_nodes:
					if other_node_id != node_id:
						var connections = _current_graph_data.graph_nodes[other_node_id].get("connections")
						if connections and node_id in connections:
							connections.erase(node_id)

				_current_graph_data.graph_nodes.erase(node_id)

		update_graph_edit()

# --- Update GraphEdit ---

func update_graph_edit():
	_graph_edit.clear_connections()

	# Dictionary to track existing nodes.
	var existing_nodes = {}
	for child in _graph_edit.get_children():
		if child is GraphNode:
			existing_nodes[child.name] = child

	if _current_graph_data:
		# Iterate through the data and update or create nodes
		for node_id in _current_graph_data.graph_nodes:
			var node_data = _current_graph_data.graph_nodes[node_id]
			var graph_node: GraphNode

			if node_id in existing_nodes:
				# Update existing node
				graph_node = existing_nodes[node_id]
				graph_node.title = str(RoomTypes.RoomType.find_key(node_data.type))
				graph_node.position_offset = node_data.position
			else:
				# Create new node
				graph_node = room_node.instantiate()
				graph_node.name = node_id
				graph_node.title = str(RoomTypes.RoomType.find_key(node_data.type))
				graph_node.position_offset = node_data.position
				_graph_edit.add_child(graph_node)

		# Connect nodes
		for node_id in _current_graph_data.graph_nodes:
			var node_data = _current_graph_data.graph_nodes[node_id]
			for connected_id in node_data.connections:
				if connected_id in _current_graph_data.graph_nodes:
					_graph_edit.connect_node(node_id, 0, connected_id, 0)

	# Clean up nodes that are no longer in the data
	for node_name in existing_nodes:
		if not node_name in _current_graph_data.graph_nodes:
			existing_nodes[node_name].queue_free()