extends Control

# UI elements
const INPUT_ = preload("uid://bfxarj13mbwjb")
@onready var all_inputs_k: VBoxContainer = %all_inputs_k
@onready var all_inputs_c: VBoxContainer = %all_inputs_c

var can_changed_input := false
var selected_key: String = ""
var selected_input_type: String = ""
var selected_UI_button: Button

# Storage variables 
var all_mapped_keys = {
	"keyboard": {},
	"controller": {}
}
var original_keys={
	"keyboard": {},
	"controller": {}
}
func _ready() -> void:
	set_original()
	get_all_mapped_keys()
	start_mapping()
	var save_manager_node = get_node_or_null("/root/SaveManager")
	if save_manager_node != null:
			save_manager_node.loaded_save_file.connect(on_load)
			save_manager_node.saved.connect(on_save)
			
			# Optional: Trigger your initial game file load sequence
			save_manager_node.load_game("game_name")
	else:
		print("Warning: SaveManager addon/autoload is not active in this project.")
		

func start_mapping():
	_clear()
	
	for key in all_mapped_keys["keyboard"]:
		var inputline: Input_Row = INPUT_.instantiate()
		all_inputs_k.add_child(inputline)
		inputline.action.text = key
		inputline.button.text = ", ".join(all_mapped_keys["keyboard"][key])
		inputline.button.pressed.connect(_on_input_changing.bind(key, "keyboard", inputline.button))
		
	for key in all_mapped_keys["controller"]:
		var inputline: Input_Row = INPUT_.instantiate()
		all_inputs_c.add_child(inputline)
		inputline.action.text = key
		inputline.button.text = ", ".join(all_mapped_keys["controller"][key])	
		inputline.button.pressed.connect(_on_input_changing.bind(key, "controller", inputline.button))

func _on_input_changing(action_name: String, input_type: String, button: Button) -> void:
	can_changed_input = true
	selected_key = action_name
	selected_input_type = input_type
	selected_UI_button = button
	
	selected_UI_button.text = "...Press Any Key..."
	print("User clicked the button for action: ", action_name)
	print("Device context to remap: ", input_type)

func _unhandled_input(event: InputEvent) -> void:
	if not can_changed_input or selected_key.is_empty():
		return
		
	
	if event is InputEventMouseButton and event.pressed:
		if selected_UI_button.get_global_rect().has_point(event.global_position):
			return
			
	# Skip echo events (holding down a key)
	if event is InputEventKey and event.is_echo():
		return

	# Only map if the input type matches what the UI slot expects
	if selected_input_type == "keyboard" and (event is InputEventKey or event is InputEventMouseButton):
		remap_keys(selected_key, event, selected_input_type, selected_UI_button)
		can_changed_input = false 
		get_viewport().set_input_as_handled()
		
	elif selected_input_type == "controller" and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		# Enforce analog drift deadzone checks
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.5:
			return
			
		remap_keys(selected_key, event, selected_input_type, selected_UI_button)
		can_changed_input = false 
		get_viewport().set_input_as_handled()

func remap_keys(action_name: String, new_event: InputEvent, input_type: String, UI_button: Button) -> void:
	var current_events = InputMap.action_get_events(action_name)
	
	for old_event in current_events:
		if input_type == "keyboard":
			if old_event is InputEventKey or old_event is InputEventMouseButton:
				InputMap.action_erase_event(action_name, old_event)
		else:
			if old_event is InputEventJoypadButton or old_event is InputEventJoypadMotion:
				InputMap.action_erase_event(action_name, old_event)	

	InputMap.action_add_event(action_name, new_event)
	get_all_mapped_keys()
	
	UI_button.text = ", ".join(all_mapped_keys[input_type][action_name])

func get_all_mapped_keys() -> void:
	all_mapped_keys = {
		"keyboard": {},
		"controller": {}
	}
	for action_name in InputMap.get_actions():
		if action_name.begins_with("ui_"):
			continue
			
		var events = InputMap.action_get_events(action_name)	
		var keyboard = get_event_keyboard(events)
		var controller = get_event_joystick(events)
		
		all_mapped_keys["keyboard"][action_name] = keyboard
		all_mapped_keys["controller"][action_name] = controller
		
func set_original() -> void:
	original_keys = {
		"keyboard": {},
		"controller": {}
	}
	for action_name in InputMap.get_actions():
		if action_name.begins_with("ui_"):
			continue
			
		var events = InputMap.action_get_events(action_name)	
		var keyboard = get_event_keyboard(events)
		var controller = get_event_joystick(events)
		
		original_keys["keyboard"][action_name] = keyboard
		original_keys["controller"][action_name] = controller
func get_event_keyboard(events: Array) -> Array:
	var keys := []
	for event in events:
		if event is InputEventKey:
			var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			var key_name = OS.get_keycode_string(code)
			if key_name != "":
				keys.append(key_name)
		elif event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT: keys.append("Left Click")
				MOUSE_BUTTON_RIGHT: keys.append("Right Click")
				MOUSE_BUTTON_MIDDLE: keys.append("Middle Click")
				MOUSE_BUTTON_WHEEL_UP: keys.append("Wheel Up")
				MOUSE_BUTTON_WHEEL_DOWN: keys.append("Wheel Down")
				_: keys.append("Mouse Button " + str(event.button_index))
	return keys
	
func get_event_joystick(events: Array) -> Array:
	var keys := []
	for event in events:
		if event is InputEventJoypadButton:
			var btn_text = ""
			match event.button_index:
				JOY_BUTTON_A: btn_text = "Button A / Cross"
				JOY_BUTTON_B: btn_text = "Button B / Circle"
				JOY_BUTTON_X: btn_text = "Button X / Square"
				JOY_BUTTON_Y: btn_text = "Button Y / Triangle"
				JOY_BUTTON_LEFT_SHOULDER: btn_text = "LB / L1"
				JOY_BUTTON_RIGHT_SHOULDER: btn_text = "RB / R1"
				JOY_BUTTON_START: btn_text = "Start"
				JOY_BUTTON_BACK: btn_text = "Back"
				JOY_BUTTON_DPAD_UP: btn_text = "D-Pad Up"
				JOY_BUTTON_DPAD_DOWN: btn_text = "D-Pad Down"
				JOY_BUTTON_DPAD_LEFT: btn_text = "D-Pad Left"
				JOY_BUTTON_DPAD_RIGHT: btn_text = "D-Pad Right"
				_: btn_text = "Joy Button " + str(event.button_index)
			keys.append(btn_text)
			
		elif event is InputEventJoypadMotion:
			if abs(event.axis_value) < 0.5:
				continue
				
			var stick_name := ""
			var direction := ""
			
			if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y:
				stick_name = "Left Stick"
			elif event.axis == JOY_AXIS_RIGHT_X or event.axis == JOY_AXIS_RIGHT_Y:
				stick_name = "Right Stick"
			elif event.axis == JOY_AXIS_TRIGGER_LEFT:
				stick_name = "Left Trigger"
			elif event.axis == JOY_AXIS_TRIGGER_RIGHT:
				stick_name = "Right Trigger"
				
			if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_RIGHT_X:
				direction = " Right" if event.axis_value > 0 else " Left"
			elif event.axis == JOY_AXIS_LEFT_Y or event.axis == JOY_AXIS_RIGHT_Y:
				direction = " Down" if event.axis_value > 0 else " Up"
			
			keys.append(stick_name + direction)
	return keys

func on_save(exported_data: Dictionary) -> void:
	# 1. Keep your human-readable dictionary text layout intact
	var data = {
		"mapped_keys": all_mapped_keys,
		"raw_input_events": {} # This will store clean, JSON-safe data arrays
	}
	
	# 2. Serialize the underlying InputEvents into plain integers/strings
	for action_name in InputMap.get_actions():
		if action_name.begins_with("ui_"):
			continue
			
		data["raw_input_events"][action_name] = []
		
		for event in InputMap.action_get_events(action_name):
			var event_data := {}
			
			if event is InputEventKey:
				event_data["type"] = "key"
				event_data["keycode"] = event.keycode
				event_data["physical_keycode"] = event.physical_keycode
				
			elif event is InputEventMouseButton:
				event_data["type"] = "mouse"
				event_data["button_index"] = event.button_index
				
			elif event is InputEventJoypadButton:
				event_data["type"] = "joy_button"
				event_data["button_index"] = event.button_index
				
			elif event is InputEventJoypadMotion:
				event_data["type"] = "joy_motion"
				event_data["axis"] = event.axis
				event_data["axis_value"] = event.axis_value
				
			if not event_data.is_empty():
				data["raw_input_events"][action_name].append(event_data)
			
	exported_data.merge(data, true)


func on_load(received_data: Dictionary) -> void:
	# 1. Rebuild the physical input events from the saved plain data data structures
	if received_data.has("raw_input_events"):
		var loaded_events: Dictionary = received_data["raw_input_events"]
		
		for action_name in loaded_events:
			if not InputMap.has_action(action_name):
				continue
				
			InputMap.action_erase_events(action_name)
			
			for event_data in loaded_events[action_name]:
				var new_event: InputEvent = null
				
				match event_data.get("type", ""):
					"key":
						new_event = InputEventKey.new()
						new_event.keycode = event_data["keycode"]
						new_event.physical_keycode = event_data["physical_keycode"]
					"mouse":
						new_event = InputEventMouseButton.new()
						new_event.button_index = event_data["button_index"]
					"joy_button":
						new_event = InputEventJoypadButton.new()
						new_event.button_index = event_data["button_index"]
					"joy_motion":
						new_event = InputEventJoypadMotion.new()
						new_event.axis = event_data["axis"]
						new_event.axis_value = event_data["axis_value"]
						
				if new_event:
					InputMap.action_add_event(action_name, new_event)

	# 2. Update your UI string layout tracking variables
	if received_data.has("mapped_keys"):
		all_mapped_keys = received_data["mapped_keys"]
	else:
		get_all_mapped_keys()
		
	# 3. Refresh the UI button displays
	start_mapping()


func _clear():
	for child in all_inputs_k.get_children():
		child.queue_free()
	for child in all_inputs_c.get_children():
		child.queue_free()

func reset_to_defaults() -> void:
	# 1. Instruct Godot to completely wipe current custom inputs 
	# and reload the pristine mappings defined in your Project Settings.
	InputMap.load_from_project_settings()
	
	# 2. Regenerate your human-readable text string dictionaries
	get_all_mapped_keys()
	
	# 3. Clear old child rows and redraw the UI lists completely fresh
	start_mapping()


func _on_save_pressed() -> void:
	var save_manager_node = get_node_or_null("/root/SaveManager")
	if save_manager_node != null:
		save_manager_node.save_game("game_name")
	else:
			print("Warning: SaveManager addon/autoload is not active in this project.")

func _on_reset_pressed() -> void:
	reset_to_defaults() 
