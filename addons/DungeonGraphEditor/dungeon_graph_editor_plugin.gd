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
var add_room_button: Button

func _enter_tree():
    # make the dock
    _dock = Control.new()
    add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)
    var window = GraphEditWindow.instantiate()
    _dock.add_child(window)

    _graph_edit = window.get_node("VBoxContainer/GraphEdit")
    toolbar = _graph_edit.get_menu_hbox()

    var new_button = Button.new()
    new_button.text = "New"
    toolbar.add_child(new_button)

    var load_button = Button.new()
    load_button.text = "Load"
    toolbar.add_child(load_button)

    var save_button = Button.new()
    save_button.text = "Save"
    toolbar.add_child(save_button)

    var add_room_button = MenuButton.new()
    add_room_button.text = "Add Room"
    toolbar.add_child(add_room_button)


    _graph_edit.connect("connection_request", Callable(self, "_on_connection_request"))
    _graph_edit.connect("disconnection_request", Callable(self, "_on_disconnection_request"))
    _graph_edit.connect("node_selected", Callable(self, "_on_node_selected"))

    new_button.connect("pressed", Callable(self, "_on_new_button_pressed"))
    load_button.connect("pressed", Callable(self, "_on_load_button_pressed"))
    save_button.connect("pressed", Callable(self, "_on_save_button_pressed"))

    var popup = add_room_button.get_popup()
    for type in RoomTypes.RoomType.keys():
        popup.add_item(type, RoomTypes.RoomType[type])
    popup.connect("id_pressed", Callable(self, "_on_add_room_button_pressed"))

# --- Graph Data Management ---

func create_new_graph_data():
    _current_graph_data = DungeonGraphData.new()
    _current_graph_data.room_type_scenes = {}
    for k in _current_graph_data.room_type_scenes:
        if not k in RoomTypes.RoomType.values():
            _current_graph_data.room_type_scenes.erase(k)
    for room_type in RoomTypes.RoomType:
            if not room_type in _current_graph_data.room_type_scenes:
                _current_graph_data.room_type_scenes[room_type] = []
    update_graph_edit()

func load_graph_data(path: String):
    var loaded_data = load(path)
    if loaded_data is DungeonGraphData:
        _current_graph_data = loaded_data
        update_graph_edit()
    else:
        push_error("Failed to load DungeonGraphData from: ", path)

func save_graph_data(path: String):
    if _current_graph_data:
        var err = ResourceSaver.save(_current_graph_data, path)
        if err != OK:
            push_error("Failed to save DungeonGraphData to: ", path)
        else:
            print("Saved")

# --- UI Callbacks ---

func _on_new_button_pressed():
    create_new_graph_data()

func _on_load_button_pressed():
    var file_dialog = FileDialog.new()
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    file_dialog.add_filter("*.tres ; Godot Resource Files")
    file_dialog.connect("file_selected", Callable(self, "load_graph_data"))
    get_tree().get_root().add_child(file_dialog)


func _on_save_button_pressed():
    var file_dialog = FileDialog.new()
    file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    file_dialog.add_filter("*.tres ; Godot Resource Files")
    file_dialog.connect("file_selected", Callable(self, "save_graph_data"))
    get_tree().get_root().add_child(file_dialog)

func _on_add_room_button_pressed(type_index: int):
    if _current_graph_data:
        var node_id = str(_current_graph_data.next_node_id)
        _current_graph_data.next_node_id += 1

        var node_data = {
            "type": type_index,
            "position": _graph_edit.get_viewport_rect().size/2,
            "connections": []
        }
        _current_graph_data.graph_nodes[node_id] = node_data

        # Use the default GraphNode
        var graph_node = room_node.instantiate()
        graph_node.name = node_id
        graph_node.title = str(RoomTypes.RoomType.find_key(type_index))  # Set title
        graph_node.position_offset = node_data.position
        # Enable both input and output slots
        # graph_node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
        _graph_edit.add_child(graph_node)
    else:
        push_warning("No graph data loaded. Create or load a graph first.")

# --- GraphEdit Callbacks ---

func _on_connection_request(from_node_name, from_slot, to_node_name, to_slot):
    print("connection request: ", from_node_name, from_slot, to_node_name, to_slot)
    if _current_graph_data:
        var from_id = str(from_node_name)
        var to_id = str(to_node_name)

        if !_current_graph_data.graph_nodes[from_id]["connections"].has(to_id):
            _current_graph_data.graph_nodes[from_id]["connections"].append(to_id)
            _graph_edit.connect_node(from_id, 0, to_id, 0)
            print(_current_graph_data.graph_nodes)

func _on_disconnection_request(from_node_name, from_slot, to_node_name, to_slot):
    print("disconnect request: ", from_node_name, from_slot, to_node_name, to_slot)
    if _current_graph_data:
        var from_id = str(from_node_name)
        var to_id = str(to_node_name)
        if _current_graph_data.graph_nodes[from_id]["connections"].has(to_id):
            _current_graph_data.graph_nodes[from_id]["connections"].erase(to_id)
            _graph_edit.disconnect_node(from_id, 0, to_id, 0)
            print(_current_graph_data.graph_nodes)

func _on_node_selected(node):
    # Could be expanded to display/edit node-specific data.
    pass

# --- Update GraphEdit ---

func update_graph_edit():
    _graph_edit.clear_connections()
    for child in _graph_edit.get_children():
        if child is GraphNode:
            child.queue_free()

    if _current_graph_data:
        for node_id in _current_graph_data.graph_nodes:
            var node_data = _current_graph_data.graph_nodes[node_id]
            # Use default GraphNode
            var graph_node = GraphNode.new()
            graph_node.name = node_id
            graph_node.title = str(RoomTypes.RoomType.keys()[node_data.type]) # Set title
            graph_node.position_offset = node_data.position
            graph_node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
            _graph_edit.add_child(graph_node)

        for node_id in _current_graph_data.graph_nodes:
            var node_data = _current_graph_data.graph_nodes[node_id]
            for connected_id in node_data.connections:
                if _current_graph_data.graph_nodes.has(connected_id):
                    _graph_edit.connect_node(node_id, 0, connected_id, 0)
