class_name StateMain
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

@export var mission_popup_container : VBoxContainer = null
@export var mission_popup_widget_class_uid : StringName

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

#================ PRIVATE ================

func _ready() -> void:
	assert(mission_popup_container)
	assert(!mission_popup_widget_class_uid.is_empty())
	
	# Clear mission popup container
	for a in mission_popup_container.get_children():
		a.queue_free()
		
#=============================== CALLBACKS ===============================

########################## END OF FILE ##########################
