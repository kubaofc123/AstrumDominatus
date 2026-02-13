class_name StateMain
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

@export_group("Setup")
@export var color_standard : Color
@export var color_bad : Color
@export_group("Internal")
@export var mission_popup_container : VBoxContainer = null
@export var mission_popup_widget_class_uid : StringName
@export var anim_player_save : AnimationPlayer = null
@export var anim_player_status : AnimationPlayer = null
@export var file_dialog : FileDialog = null
@export var button_load_save_file : Button = null
@export var label_save_file_status_value : Label = null
@export var label_save_file_name_value : Label = null

var file_status_label_shown : bool = false

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

#================ PRIVATE ================

func _ready() -> void:
	assert(mission_popup_container)
	assert(!mission_popup_widget_class_uid.is_empty())
	assert(anim_player_save)
	assert(anim_player_status)
	assert(file_dialog)
	assert(button_load_save_file)
	assert(label_save_file_status_value)
	assert(label_save_file_name_value)
	
	# Signals
	anim_player_save.animation_finished.connect(_on_anim_player_save_animation_finished)
	button_load_save_file.pressed.connect(_on_button_load_save_file_pressed)
	file_dialog.file_selected.connect(_on_file_dialog_file_selected)
	
	# Clear mission popup container
	for a in mission_popup_container.get_children():
		a.queue_free()
		
#=============================== CALLBACKS ===============================

func _on_anim_player_save_animation_finished(p_anim_name : StringName) -> void:
	match p_anim_name:
		"a_save_file_status":
			if not file_status_label_shown:
				anim_player_save.play("a_save_file_status_value")
				file_status_label_shown = true
		_:
			pass


func _on_button_load_save_file_pressed() -> void:
	file_dialog.visible = true


func _on_file_dialog_file_selected(p_path : String) -> void:
	var __result : Main.ESaveFileValidity = Global.main._is_valid_save_file(p_path)
	
	if anim_player_save.is_playing() and anim_player_save.current_animation == "a_save_file_status":
		await anim_player_save.animation_finished
		
	anim_player_save.play("a_save_file_status_value")
	file_status_label_shown = true
	
	label_save_file_name_value.text = p_path.get_file().get_basename()
	
	if __result == Main.ESaveFileValidity.VALID:
		label_save_file_status_value.text = "Approved"
		label_save_file_status_value.add_theme_color_override("font_color", color_standard)
		label_save_file_name_value.add_theme_color_override("font_color", color_standard)
	else:
		label_save_file_status_value.text = "Rejected"
		label_save_file_status_value.add_theme_color_override("font_color", color_bad)
		label_save_file_name_value.add_theme_color_override("font_color", color_bad)
		
	
########################## END OF FILE ##########################
