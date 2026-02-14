class_name Main
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

@export_group("Setup")
@export var required_mods_list : PackedStringArray		## List of mods that need to be in the save file in order to load
@export var mod_blacklist : PackedStringArray				## List of mods that if they appear in save file, app will not load the save
@export_group("Setup/Backend")
@export var backend_address : String						## Address of the backend where the results are being sent and status is received
@export var backend_read_key : String					## Backend API key to receive status
@export_group("Setup/Nodes")
@export var state_container : Node = null

var current_state : Main.EState = EState.INIT

enum EState {INIT = 0, LOGIN = 1, MAIN = 2}
enum ESaveFileValidity {VALID = 0, INVALID = 1, FILE_LOCKED = 2, BLACKLIST_MOD_PRESENT = 3, REQUIRED_MOD_MISSING = 4}

#================ PRIVATE ================

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

func load_state(p_state : Main.EState) -> void:
	# Clear old state
	for a in state_container.get_children():
		a.queue_free()
	
	# Load new state
	current_state = p_state
	match current_state:
		Main.EState.INIT:
			var __scene : PackedScene = EngineScriptLibrary.utility.load_asset("uid://s0jlxq6j4xo6")
			var __new_state : StateInit = __scene.instantiate()
			state_container.add_child(__new_state)
		
		Main.EState.LOGIN:
			var __scene : PackedScene = EngineScriptLibrary.utility.load_asset("uid://c5uk4kwk32em6")
			var __new_state : StateLogin = __scene.instantiate()
			state_container.add_child(__new_state)
		
		Main.EState.MAIN:
			var __scene : PackedScene = EngineScriptLibrary.utility.load_asset("uid://cmiuvqw00m57i")
			var __new_state : StateMain = __scene.instantiate()
			state_container.add_child(__new_state)
		
		_:
			pass
	
#================ PRIVATE ================

func _ready() -> void:
	# Startup checks
	assert(state_container)
	
	# Register at Global
	Global.main = self
	
	# Scale the app window to 1/2 screen size
	_resize_and_reposition_window()
	
	# Load init state
	load_state(Main.EState.INIT)
	
	
func _resize_and_reposition_window() -> void:
	var __original_viewport_size : Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	var __new_viewport_size = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())/2.0
	__new_viewport_size.x = __new_viewport_size.y * 1.777777777778
	get_viewport().get_window().size = __new_viewport_size
	get_viewport().get_window().position = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())/4.0 + Vector2(DisplayServer.screen_get_position(DisplayServer.get_primary_screen()))


func _is_valid_save_file(p_path : String) -> ESaveFileValidity:
	# Exit if empty path was provided
	if p_path.is_empty():
		return ESaveFileValidity.INVALID
	
	# Exit of couldn't open the save file
	var __reader : ZIPReader = ZIPReader.new()
	var _err : Error = __reader.open(p_path)
	if _err != Error.OK:
		return ESaveFileValidity.INVALID
	
	# Exit if "status" file doesn't exist
	if not __reader.file_exists("status"):
		return ESaveFileValidity.INVALID
	
	# Read the "status" file as bytes
	var __bytes : PackedByteArray = __reader.read_file("status")
	__reader.close()
	
	# Parse bytes into array of strings, where each line is one entry
	var __file_string : String = __bytes.get_string_from_utf8()
	var __string_arr : PackedStringArray = __file_string.split("\n")
	
	# Find save version
	var __save_version : int = 0
	for a in __string_arr:
		if a.strip_edges().begins_with("{version"):
			__save_version = int(a.remove_chars("{}").get_slice(" ",1))
			break
	
	# Process file
	match __save_version:
		9:
			# Find mods line indexes
			var __mods_line_start_idx : int = 0
			var __mods_line_end_idx : int = 0
			for i in __string_arr.size():
				# Search for mods start
				if __mods_line_start_idx == 0:
					if __string_arr[i].strip_edges().begins_with("{mods"):
						__mods_line_start_idx = i + 1
						continue
				elif __mods_line_end_idx == 0:
					if __string_arr[i].strip_edges() == "}":
						__mods_line_end_idx = i
						break
			
			if __mods_line_start_idx == 0 or __mods_line_end_idx == 0:
				return ESaveFileValidity.INVALID
			
			# Create mod list
			var __mods_string_arr : PackedStringArray = __string_arr.slice(__mods_line_start_idx, __mods_line_end_idx)
			
			# Sanitize mod list
			for i in __mods_string_arr.size():
				__mods_string_arr[i] = __mods_string_arr[i].get_slice(":", 0)
				__mods_string_arr[i] = __mods_string_arr[i].remove_chars("\"")
				__mods_string_arr[i] = __mods_string_arr[i].strip_edges()
			
			# Process blacklist
			for a in mod_blacklist:
				if __mods_string_arr.has(a):
					return ESaveFileValidity.BLACKLIST_MOD_PRESENT
			
			# Process required mods list
			var __all_required_mods_found : bool = true
			for a in required_mods_list:
				if not __mods_string_arr.has(a):
					__all_required_mods_found = false
					break
			if not __all_required_mods_found:
				return ESaveFileValidity.REQUIRED_MOD_MISSING
			
		_:
			pass
	
	
	return ESaveFileValidity.VALID


func _load_save_file(p_path : String) -> Error:
	
	return Error.OK
	
#=============================== CALLBACKS ===============================

########################## END OF FILE ##########################
