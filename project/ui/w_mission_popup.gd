extends Control

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

@export var _button : Button = null

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

#================ PRIVATE ================

func _ready() -> void:
	assert(_button)
	
	_button.pressed.connect(_on_button_pressed)
	
#=============================== CALLBACKS ===============================

func _on_button_pressed() -> void:
	if not is_queued_for_deletion():
		queue_free()
		
########################## END OF FILE ##########################
