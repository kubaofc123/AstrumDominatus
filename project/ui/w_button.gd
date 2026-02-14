@tool
class_name AstrumButton
extends Panel

#=============================== VARIABLES ===============================

#================ PUBLIC ================

signal signal_pressed()
signal signal_hovered()
signal signal_unhovered()

#================ PRIVATE ================

@export_group("Setup")
@export var _style_box_normal : StyleBox
@export var _style_box_hover : StyleBox
@export var _label_color_normal : Color
@export var _label_color_hover : Color
@export var _text : String:
	get():
		return _text
	set(value):
		_text = value
		if _label:
			_label.text = _text
@export_group("Internal")
@export var _label : Label = null

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

#================ PRIVATE ================

func _ready() -> void:
	assert(_label)
	
	# Signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	_label.text = _text
	
#=============================== CALLBACKS ===============================

func _on_mouse_entered() -> void:
	add_theme_stylebox_override(&"panel", _style_box_hover)
	_label.add_theme_color_override(&"font_color", _label_color_hover)
	signal_hovered.emit()


func _on_mouse_exited() -> void:
	add_theme_stylebox_override(&"panel", _style_box_normal)
	_label.add_theme_color_override(&"font_color", _label_color_normal)
	signal_unhovered.emit()
	

func _on_gui_input(p_event : InputEvent) -> void:
	var __cast_event : InputEventMouseButton = p_event as InputEventMouseButton
	if __cast_event and __cast_event.pressed:
		signal_pressed.emit()
	
########################## END OF FILE ##########################
