class_name StateInit
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

#================ PRIVATE ================

@export var _anim_player : AnimationPlayer = null
@export var _control : Control = null

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

#================ PRIVATE ================

func _ready() -> void:
	# Checks
	assert(_anim_player)
	assert(_control)
	
	# Signals
	_anim_player.animation_finished.connect(_on_animation_finished)
	_control.gui_input.connect(_on_gui_input)
	
#=============================== CALLBACKS ===============================

func _on_animation_finished(p_anim_name : StringName) -> void:
	Global.main.load_state(Main.EState.LOGIN)


func _on_gui_input(p_event : InputEvent) -> void:
	if p_event as InputEventMouseButton:
		Global.main.load_state(Main.EState.LOGIN)
	
########################## END OF FILE ##########################
