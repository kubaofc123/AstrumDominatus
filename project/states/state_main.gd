class_name StateMain
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

@export_group("Setup")
@export var color_standard : Color
@export var color_bad : Color
@export_group("Internal")
@export var directory_watcher : DirectoryWatcher = null
@export var mission_popup_container : VBoxContainer = null
@export var mission_popup_widget_class_uid : StringName
@export var anim_player_save : AnimationPlayer = null
@export var anim_player_save_info : AnimationPlayer = null
@export var anim_player_status : AnimationPlayer = null
@export var file_dialog : FileDialog = null
@export var button_load_save_file : Button = null
@export var label_save_file_status_value : Label = null
@export var label_save_file_name_value : Label = null
@export var label_save_info : Label = null

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
	assert(button_load_save_file)
	assert(label_save_file_status_value)
	assert(label_save_file_name_value)
	
	# Signals
	anim_player_save.animation_finished.connect(_on_anim_player_save_animation_finished)
	button_load_save_file.pressed.connect(_on_button_load_save_file_pressed)
	file_dialog.file_selected.connect(_on_file_dialog_file_selected)
	directory_watcher.files_modified.connect(_on_directory_watcher_filed_modified)
	
	# Directory Watcher setup
	directory_watcher.scan_delay = 2.0
	
	# Clear mission popup container
	for a in mission_popup_container.get_children():
		a.queue_free()
		
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


func _on_file_dialog_file_selected(p_path : String) -> void:
	var __result : Main.ESaveFileValidity = Global.main._is_valid_save_file(p_path)
	
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
		label_save_file_status_value.add_theme_color_override("font_color", color_standard)
		label_save_file_name_value.add_theme_color_override("font_color", color_standard)
		if not directory_watcher.is_scanning_directory(__new_scan_directory):
			directory_watcher.add_scan_directory(__new_scan_directory)
		_valid_save_file_path = p_path
		anim_player_save_info.play("a_save_info")
	else:
		label_save_file_status_value.text = "Rejected"
		label_save_file_status_value.add_theme_color_override("font_color", color_bad)
		label_save_file_name_value.add_theme_color_override("font_color", color_bad)
		_valid_save_file_path = ""
		label_save_info.visible_ratio = 0.0
		
		
func _on_directory_watcher_filed_modified(p_files : PackedStringArray) -> void:
	print("Files modified: ", p_files)
	
	# Check if save file was among modified files
	var __idx : int = p_files.find(_valid_save_file_path)
	if __idx == -1:
		return
	
	print("Loaded save was modified")
	var __popup_widget_class : PackedScene = EngineScriptLibrary.utility.load_asset(mission_popup_widget_class_uid)
	assert(__popup_widget_class)
	var __popup_widget_node : Control = __popup_widget_class.instantiate()
	mission_popup_container.add_child(__popup_widget_node)
	
########################## END OF FILE ##########################
