class_name StateMain
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

@export_group("Setup")
@export var color_standard : Color
@export var color_bad : Color
@export var directory_scan_time : float = 1.0
@export_group("Internal")
@export var directory_watcher : DirectoryWatcher = null
@export var mission_popup_container : VBoxContainer = null
@export var mission_popup_widget_class_uid : StringName
@export var anim_player_save : AnimationPlayer = null
@export var anim_player_save_info : AnimationPlayer = null
@export var anim_player_status : AnimationPlayer = null
@export var file_dialog : FileDialog = null
@export var save_file_read_timer : Timer = null
@export var button_load_save_file : AstrumButton = null
@export var button_update_status : AstrumButton = null
@export var label_save_file_status_value : Label = null
@export var label_save_file_name_value : Label = null
@export var label_save_info : Label = null
@export var label_faction_control_percent : Label = null
@export var progress_bar : ProgressBar = null

var _file_status_label_shown : bool = false
var _valid_save_file_path : String

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

#================ PRIVATE ================

func _ready() -> void:
	assert(directory_watcher)
	assert(mission_popup_container)
	assert(!mission_popup_widget_class_uid.is_empty())
	assert(anim_player_save)
	assert(anim_player_save_info)
	assert(anim_player_status)
	assert(file_dialog)
	assert(save_file_read_timer)
	assert(button_load_save_file)
	assert(button_update_status)
	assert(label_save_file_status_value)
	assert(label_save_file_name_value)
	assert(label_save_info)
	assert(label_faction_control_percent)
	assert(progress_bar)
	
	# Signals
	anim_player_save.animation_finished.connect(_on_anim_player_save_animation_finished)
	button_load_save_file.signal_pressed.connect(_on_button_load_save_file_pressed)
	button_update_status.signal_pressed.connect(_on_button_update_status_pressed)
	file_dialog.file_selected.connect(_on_file_dialog_file_selected)
	directory_watcher.files_modified.connect(_on_directory_watcher_filed_modified)
	Global.main.backend_connection.signal_planet_status_response.connect(_on_planet_status_response)
	Global.main.backend_connection.signal_successful_operation_response.connect(_on_successful_operation_response)
	
	# Directory Watcher setup
	directory_watcher.scan_delay = directory_scan_time
	
	# Clear mission popup container
	for a in mission_popup_container.get_children():
		a.queue_free()


func _create_save_info_text(p_dictionary : Dictionary) -> void:
	var __string : String = "Army : {army}\nOperation Days : {operation_days}\nDifficulty : {difficulty}\nVictories : {victories}\nDefeats : {defeats}\n{attacking}"
	label_save_info.text = __string.format(p_dictionary)
	
#=============================== CALLBACKS ===============================

func _on_anim_player_save_animation_finished(p_anim_name : StringName) -> void:
	match p_anim_name:
		"a_save_file_status":
			if not _file_status_label_shown:
				anim_player_save.play("a_save_file_status_value")
				_file_status_label_shown = true
		_:
			pass


func _on_button_load_save_file_pressed() -> void:
	file_dialog.visible = true


func _on_button_update_status_pressed() -> void:
	Global.main.backend_connection.get_planet_status()
	
	
func _on_file_dialog_file_selected(p_path : String) -> void:
	var __result : Main.ESaveFileValidity = Global.main.is_valid_save_file(p_path)
	var __loop_count : int = 0
	while __result == Main.ESaveFileValidity.SAVE_LOCKED and __loop_count < 10:
		__loop_count += 1
		await get_tree().create_timer(1.0).timeout
		__result = Global.main.is_valid_save_file(p_path)
	
	if anim_player_save.is_playing() and anim_player_save.current_animation == "a_save_file_status":
		await anim_player_save.animation_finished
	
	anim_player_save.play("a_save_file_status_value")
	_file_status_label_shown = true
	
	# Set save file name label text
	label_save_file_name_value.text = p_path.get_file().get_basename()
	
	# Directory watcher update
	var __old_scan_directory : String = _valid_save_file_path.get_base_dir()
	var __new_scan_directory : String = p_path.get_base_dir()
	if not _valid_save_file_path.is_empty():
		if not directory_watcher.is_scanning_directory(__new_scan_directory):
			directory_watcher.remove_scan_directory(__old_scan_directory)
	
	if __result == Main.ESaveFileValidity.VALID:
		label_save_file_status_value.text = "Approved"
		label_save_file_status_value.add_theme_color_override(&"font_color", color_standard)
		label_save_file_name_value.add_theme_color_override(&"font_color", color_standard)
		if not directory_watcher.is_scanning_directory(__new_scan_directory):
			directory_watcher.add_scan_directory(__new_scan_directory)
		_valid_save_file_path = p_path
		
		var __save_file_data_dict : Dictionary
		Global.main.load_save_file(p_path, __save_file_data_dict)
		Global.main.update_astrum_data_file(p_path, __save_file_data_dict)
		_create_save_info_text(__save_file_data_dict)
		anim_player_save_info.play("a_save_info")
	else:
		label_save_file_status_value.text = "Rejected"
		label_save_file_status_value.add_theme_color_override(&"font_color", color_bad)
		label_save_file_name_value.add_theme_color_override(&"font_color", color_bad)
		_valid_save_file_path = ""
		label_save_info.visible_ratio = 0.0
		Global.main.loaded_astrum_dominatus_data_dictionary.clear()
		
		
func _on_directory_watcher_filed_modified(p_files : PackedStringArray) -> void:
	print("Files modified: ", p_files)
	
	# Check if save file was among modified files
	var __idx : int = p_files.find(_valid_save_file_path)
	if __idx == -1:
		return
	
	if not save_file_read_timer.timeout.is_connected(_on_save_file_read_timer_timeout.bind(p_files[__idx])):
		save_file_read_timer.timeout.connect(_on_save_file_read_timer_timeout.bind(p_files[__idx]), ConnectFlags.CONNECT_ONE_SHOT)
	save_file_read_timer.start(directory_scan_time + 1.0)
	

func _on_save_file_read_timer_timeout(p_file_path : String) -> void:
	print("Loaded save was modified")
	
	var __save_file_data_dict : Dictionary
	Global.main.load_save_file(p_file_path, __save_file_data_dict)
	
	# If save got modified but all data is the same, don't refresh UI
	if __save_file_data_dict == Global.main.loaded_astrum_dominatus_data_dictionary:
		return
	
	# Detect if there was a new victory
	var __victory_detected : bool = false
	var __failure_detected : bool = false
	if __save_file_data_dict["operation_days"] > Global.main.loaded_astrum_dominatus_data_dictionary["operation_days"]:
		if __save_file_data_dict["victories"] > Global.main.loaded_astrum_dominatus_data_dictionary["victories"]:
			__victory_detected = true
		else:
			__failure_detected = true
	
	# Update UI
	_create_save_info_text(__save_file_data_dict)
	anim_player_save_info.play("a_save_info")
	
	# Update loaded data
	Global.main.update_astrum_data_file(p_file_path, __save_file_data_dict)
	
	if __failure_detected:
		var __popup_widget_class : PackedScene = EngineScriptLibrary.utility.load_asset(mission_popup_widget_class_uid)
		assert(__popup_widget_class)
		var __popup_widget_node : MissionPopupWidget = __popup_widget_class.instantiate()
		__popup_widget_node.set_failure_text()
		mission_popup_container.add_child(__popup_widget_node)
	
	# Send victory notification to backend
	if __victory_detected:
		Global.main.backend_connection.submit_successful_operation_result()


func _on_planet_status_response(p_data : Dictionary) -> void:
	if not p_data.has("planet_data"):
		return
	
	progress_bar.max_value = float(p_data["planet_data"]["max_value"])
	progress_bar.value = float(p_data["planet_data"]["value"])
	
	var __planet_control_percent_string : String = str((float(p_data["planet_data"]["value"]) / float(p_data["planet_data"]["max_value"])) * 100.0).pad_decimals(2)
	label_faction_control_percent.text = "Imperial Control at {0}%".format([__planet_control_percent_string])


func _on_successful_operation_response(p_data : Dictionary) -> void:
	if not p_data.has("planet_data"):
		return
		
	progress_bar.max_value = float(p_data["planet_data"]["max_value"])
	progress_bar.value = float(p_data["planet_data"]["value"])
	
	var __planet_control_percent_string : String = str((float(p_data["planet_data"]["value"]) / float(p_data["planet_data"]["max_value"])) * 100.0).pad_decimals(2)
	label_faction_control_percent.text = "Imperial Control at {0}%".format([__planet_control_percent_string])
		
	# Show popup
	var __progress_percent : float = (float(p_data["contribution_points"]) / float(p_data["planet_data"]["max_value"])) * 100.0
	var __popup_widget_class : PackedScene = EngineScriptLibrary.utility.load_asset(mission_popup_widget_class_uid)
	assert(__popup_widget_class)
	var __popup_widget_node : MissionPopupWidget = __popup_widget_class.instantiate()
	__popup_widget_node.set_victory_text(__progress_percent)
	mission_popup_container.add_child(__popup_widget_node)
	
########################## END OF FILE ##########################
