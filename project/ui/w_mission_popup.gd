class_name MissionPopupWidget
extends Control

#=============================== VARIABLES ===============================

#================ PUBLIC ================


#================ PRIVATE ================

@export_group("Setup")
@export var color_normal : Color
@export var color_failure : Color
@export var stylebox_normal : StyleBox = null
@export var stylebox_failure : StyleBox = null
@export_group("Internal")
@export var _panel : Panel = null
@export var _button : Button = null
@export var _label : Label = null

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

func set_victory_text(p_percent : float) -> void:
	_label.text = "Mission success\nControl increase: {0}%".format([str(p_percent).pad_decimals(4)])
	_label.add_theme_color_override(&"font_color", color_normal)
	_panel.add_theme_stylebox_override(&"panel", stylebox_normal)


func set_failure_text() -> void:
	_label.text = "Mission failed"
	_label.add_theme_color_override(&"font_color", color_failure)
	_panel.add_theme_stylebox_override(&"panel", stylebox_failure)
	
#================ PRIVATE ================

func _ready() -> void:
	assert(_panel)
	assert(_label)
	assert(_button)
	
	_button.pressed.connect(_on_button_pressed)
	
#=============================== CALLBACKS ===============================

func _on_button_pressed() -> void:
	if not is_queued_for_deletion():
		queue_free()
		
########################## END OF FILE ##########################
