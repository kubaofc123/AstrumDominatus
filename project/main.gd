class_name Main
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

@export_group("Setup")
@export var app_type_name : String = "Indomitus"
@export var required_mods_list : PackedStringArray		## List of mods that need to be in the save file in order to load
@export var mod_blacklist : PackedStringArray				## List of mods that if they appear in save file, app will not load the save
@export_group("Setup/Backend")
@export var backend_address : String						## Address of the backend where the results are being sent and status is received
@export var backend_port : int = 35000
@export var backend_read_key : String					## Backend API key to receive status
@export_group("Setup/Nodes")
@export var state_container : Node = null
@export_group("Internal")
@export var backend_connection : BackendConnection = null

var current_state : Main.EState = EState.INIT
var loaded_astrum_dominatus_data_dictionary : Dictionary

enum EState {INIT = 0, LOGIN = 1, MAIN = 2}
enum ESaveFileValidity {VALID = 0, INVALID = 1, SAVE_LOCKED = 2, MISSING_FILE_IN_SAVE = 3, BLACKLIST_MOD_PRESENT = 4, REQUIRED_MOD_MISSING = 5}
enum ELoadSaveResult {OK = 0, SAVE_NOT_FOUND = 1, SAVE_LOCKED = 2, MISSING_FILE_IN_SAVE = 3, CANT_CREATE_ASTRUM_DOMINATUS_DATA_FILE = 4}

const ASTRUM_DOMINATUS_DATA_FILE_NAME : String = "astrum_dominatus_data"

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


func is_valid_save_file(p_path : String) -> ESaveFileValidity:
	# Exit if empty path was provided
	if p_path.is_empty():
		return ESaveFileValidity.INVALID
	
	if not FileAccess.file_exists(p_path):
		return ESaveFileValidity.INVALID
	
	# Exit if couldn't open the save file
	var __reader : ZIPReader = ZIPReader.new()
	var _err : Error = __reader.open(p_path)
	if _err != Error.OK:
		__reader.close()
		return ESaveFileValidity.SAVE_LOCKED
	
	# Exit if "status" file doesn't exist
	if not __reader.file_exists("status"):
		push_warning("is_valid_save_file: status file missing, file list: ", __reader.get_files())
		__reader.close()
		return ESaveFileValidity.MISSING_FILE_IN_SAVE
	
	# Read the "status" file as bytes
	var __bytes : PackedByteArray = __reader.read_file("status")
	__reader.close()
	
	# Parse bytes into array of strings, where each line is one entry
	var __file_string : String = __bytes.get_string_from_utf8()
	var __string_arr : PackedStringArray = __file_string.split("\n")
	
	# Sanitize array
	for i in __string_arr.size():
		__string_arr[i] = __string_arr[i].strip_edges()
	
	# Find save version
	var __save_version : int = 0
	for a in __string_arr:
		if a.strip_edges().begins_with("{version"):
			__save_version = int(a.remove_chars("{}").get_slice(" ",1))
			break
	
	# Process file
	match __save_version:
		_:
			# Find mods line indexes
			var __mods_line_start_idx : int = 0
			var __mods_line_end_idx : int = 0
			for i in __string_arr.size():
				# Search for mods start
				if __mods_line_start_idx == 0:
					if __string_arr[i].begins_with("{mods"):
						__mods_line_start_idx = i + 1
						continue
				elif __mods_line_end_idx == 0:
					if __string_arr[i] == "}":
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

	return ESaveFileValidity.VALID


func load_save_file(p_path : String, p_result_dictionary : Dictionary) -> ELoadSaveResult:
	# Exit if empty path was provided
	if p_path.is_empty():
		return ELoadSaveResult.SAVE_NOT_FOUND
	
	if not FileAccess.file_exists(p_path):
		return ELoadSaveResult.SAVE_NOT_FOUND
	
	# Exit of couldn't open the save file
	var __reader : ZIPReader = ZIPReader.new()
	var _err : Error = __reader.open(p_path)
	if _err != Error.OK:
		__reader.close()
		return ELoadSaveResult.SAVE_LOCKED
	
	# Exit if "status" file in save doesn't exist
	if not __reader.file_exists("status"):
		__reader.close()
		return ELoadSaveResult.MISSING_FILE_IN_SAVE
	
	# Check if Astrum Dominatus data file if missing
	var __ad_data_file_missing : bool = false
	if not __reader.file_exists(ASTRUM_DOMINATUS_DATA_FILE_NAME):
		__ad_data_file_missing = true
		
	# Read the "status" file as bytes
	var __bytes : PackedByteArray = __reader.read_file("status")
	
	# Close reader
	__reader.close()
	
	# Parse bytes into array of strings, where each line is one entry
	var __file_string : String = __bytes.get_string_from_utf8()
	var __string_arr : PackedStringArray = __file_string.split("\n")
	
	# Sanitize array
	for i in __string_arr.size():
		__string_arr[i] = __string_arr[i].strip_edges()
		
	# Find save version
	var __save_version : int = 0
	for a in __string_arr:
		if a.strip_edges().begins_with("{version"):
			__save_version = int(a.remove_chars("{}").get_slice(" ",1))
			break
	
	# Process file
	match __save_version:
		_:
			var __army : String
			var __operation_days : int = -1
			var __difficulty : String
			var __victories : int = -1
			var __defeats : int = -1
			var __attacking : String
			
			for a in __string_arr:
				# Army
				if __army.is_empty():
					if a.begins_with("{army"):
						__army = a.get_slice(" ", 1).trim_suffix("}")
						match __army:
							"ig":
								__army = "Imperial Guard"
							"tg":
								__army = "Traitor Guard"
							_:
								__army = "Unknown"
						continue
				
				# Operation days
				if __operation_days == -1:
					if a.begins_with("{playedGames"):
						__operation_days = int(a.get_slice(" ", 1).trim_suffix("}"))
						continue
				
				# Difficulty
				if __difficulty.is_empty():
					if a.begins_with("{difficulty"):
						__difficulty = a.get_slice(" ", 1).trim_suffix("}")
						continue
				
				# Victories
				if __victories == -1:
					if a.begins_with("{wonGames"):
						__victories = int(a.get_slice(" ", 1).trim_suffix("}"))
						continue
				
				# Attacking
				if __attacking.is_empty():
					if a.begins_with("{attacking"):
						if a.ends_with("0}"):
							__attacking = "Defending"
						else:
							__attacking = "Attacking"
						continue
				
				if not __army.is_empty() and __operation_days != -1 and not __difficulty.is_empty() and __victories != -1 and not __attacking.is_empty():
					break
			
			# Defeats
			__defeats = __operation_days - __victories
			
			p_result_dictionary["army"] = __army
			p_result_dictionary["operation_days"] = __operation_days
			p_result_dictionary["difficulty"] = __difficulty
			p_result_dictionary["victories"] = __victories
			p_result_dictionary["defeats"] = __defeats
			p_result_dictionary["attacking"] = __attacking
			
			if __operation_days == -1:
				push_warning("Failed to read save file, dumping:", __file_string)
	
	return ELoadSaveResult.OK


func update_astrum_data_file(p_path : String, p_result_dictionary : Dictionary) -> void:
	loaded_astrum_dominatus_data_dictionary = p_result_dictionary
	#loaded_astrum_dominatus_data_dictionary["file_path"] = p_path
#	var __save_file_files_dict : Dictionary	# FileName - Bytes
#	
#	# Store all files in memory
#	var __reader : ZIPReader = ZIPReader.new()
#	var _err : Error = __reader.open(p_path)
#	if _err != Error.OK:
#		__reader.close()
#		push_error("_update_astrum_data_file: Can't open save file")
#		return
#	var __files_list : PackedStringArray = __reader.get_files()
#	for __file in __files_list:
#		# Skip Astrum Dominatus data file
#		if __file == ASTRUM_DOMINATUS_DATA_FILE_NAME:
#			continue
#		__save_file_files_dict[__file] = __reader.read_file(__file)
#	
#	# Write back the save files
#	var __writer : ZIPPacker = ZIPPacker.new()
#	_err = __writer.open(p_path)
#	if _err != Error.OK:
#		__writer.close()
#		push_error("_update_astrum_data_file: failure")
#		return
#	for __file in __files_list:
#		# Skip Astrum Dominatus data file
#		if __file == ASTRUM_DOMINATUS_DATA_FILE_NAME:
#			continue
#		__writer.start_file(__file)
#		__writer.write_file(__save_file_files_dict[__file])
#		__writer.close_file()
#	__writer.start_file(ASTRUM_DOMINATUS_DATA_FILE_NAME)
#	var __bytes : PackedByteArray = var_to_bytes(p_result_dictionary)
#	__writer.write_file(__bytes)
#	__writer.close_file()
#	__writer.close()

#================ PRIVATE ================

func _enter_tree() -> void:
	# Register at Global
	Global.main = self
	
	
func _ready() -> void:
	# Startup checks
	assert(state_container)
	assert(backend_connection)
	
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

#=============================== CALLBACKS ===============================

########################## END OF FILE ##########################
