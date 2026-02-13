class_name StateLogin
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

#================ PRIVATE ================

#func _ready() -> void:
#	Global.main.load_state(Main.EState.MAIN)

#=============================== CALLBACKS ===============================

func _on_button_pressed() -> void:
	Global.main.load_state(Main.EState.MAIN)
	
########################## END OF FILE ##########################
