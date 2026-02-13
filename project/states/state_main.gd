class_name StateMain
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

@export var mission_popup_container : VBoxContainer = null
@export var mission_popup_widget_class_uid : StringName
@export var anim_player_save : AnimationPlayer = null
@export var anim_player_status : AnimationPlayer = null
@export var file_dialog : FileDialog = null
@export var button_load_save_file : Button = null

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
	
	# Signals
	anim_player_save.animation_finished.connect(_on_anim_player_save_animation_finished)
	button_load_save_file.pressed.connect(_on_button_load_save_file_pressed)
	
	# Clear mission popup container
	for a in mission_popup_container.get_children():
		a.queue_free()
		
#=============================== CALLBACKS ===============================

func _on_anim_player_save_animation_finished(p_anim_name : StringName) -> void:
	match p_anim_name:
		"a_save_file":
			anim_player_save.play("a_save_file_status")
		_:
			pass


func _on_button_load_save_file_pressed() -> void:
	file_dialog.visible = true
	
########################## END OF FILE ##########################
