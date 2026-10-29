# Godot 4 Input Remapper Addon

A flexible, modular input remapping system for Godot 4.3+ that automatically generates options menus for both Keyboard/Mouse and Gamepad controllers. 

It handles unified cross-platform controller button strings, removes analog stick drifts during rebinding, and breaks down `InputEvent` data definitions into clean, primitive data packets safe for any custom save manager.

## Features

- 🎮 **Unified Gamepad Layouts:** Reads and normalizes Xbox, PlayStation, and Nintendo Switch layouts via standard internal engine mapping strings.
- ⌨️ **Isolated Remapping Loops:** Independently update keyboard/mouse setups or gamepads without erasing configuration bindings from the opposite device layer.
- 🧭 **Drift-Safe Analog Detection:** Built-in deadzone filters ensure joystick directions (`Up`, `Down`, `Left`, `Right`) and analog triggers are captured accurately.
- 🛠️ **Auto-Generating UI Lists:** Dynamically reads non-system actions from your Project Settings and populates separate keyboard and controller VBoxContainers.
- 💾 **Safe Data Serialization:** Safely serializes active events down to pure primitives (`int`, `float`, `string`) to avoid type crashes with text-based or JSON save managers.
- 🔄 **One-Click Factory Reset:** Instantly load default project configurations using core engine calls with full runtime UI propagation.

## Installation

1. Create an `addons/` folder inside your root project directory if it does not already exist.
2. Drop the plugin directory containing the code files directly into `res://addons/`.
3. Go to **Project > Project Settings > Plugins** and change the status of the Input Remapper plugin to **Enabled**.

## Code Structure Overview

The script works by separating data serialization (saving raw parameters like `keycode` or `axis_value`) from visual presentation text:

- `get_event_keyboard()` & `get_event_joystick()`: Turn physical, runtime user inputs into descriptive UI button strings (e.g., `"Left Stick Up"`, `"Right Click"`).
- `on_save()` & `on_load()`: Cleanly extract primitive properties for external save systems without transferring volatile memory object handles.
- `reset_to_defaults()`: Discards active control layers to restore pristine, project-defined settings templates safely.

## Save Manager Integration

The addon safely attempts to resolve global save hooks on load. If your game utilizes a custom global save system (e.g., an Autoload named `SaveManager`), it will automatically tie into its save and load signal chains:
Dowload link : https://store.godotengine.org/asset/whats-code/save-manager/
```gdscript
# Safe initialization hook inside _ready()
var save_manager_node = get_node_or_null("/root/SaveManager")
if save_manager_node != null:
	save_manager_node.loaded_save_file.connect(on_load)
	save_manager_node.saved.connect(on_save)
```

If no `SaveManager` autoload is detected, the plugin gracefully falls back to local configuration handling without failing or causing engine environment execution crashes.
