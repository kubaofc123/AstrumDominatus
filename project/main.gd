class_name Main
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

@export var state_container : Node = null

var current_state : Main.EState = EState.INIT

enum EState {INIT = 0, LOGIN = 1, MAIN = 2}

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
			pass
		
		Main.EState.MAIN:
			pass
		
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

#=============================== CALLBACKS ===============================

########################## END OF FILE ##########################
