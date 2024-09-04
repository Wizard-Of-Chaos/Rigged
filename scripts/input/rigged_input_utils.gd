extends Node
class_name RiggedInputUtils


const VIRTUAL_DEVICE_OFFSET := -18
const MAX_CONNECTED_CONTROLLERS := 16

const ACTION_SET_IN_GAME_CONTROLS: String = "InGameControls"
const ACTION_SET_MENU_CONTROLS: String = "MenuControls"

class ActionSet:
	var handle: int = 0
	var name: String
	var actions: Array[Action]
	var is_action_set_layer: bool
	func _init(p_name: String, p_actions: Array[Action], p_is_action_set_layer: bool = false) -> void:
		self.name = p_name
		self.actions = p_actions
		self.is_action_set_layer = p_is_action_set_layer


class Action:
	var handle: int
	var name: String
	func _init(p_name: String) -> void:
		self.handle = 0
		self.name = p_name


class AnalogAction extends Action:
	var pos_x_equiv: String
	var pos_x_last_val: Dictionary
	var neg_x_equiv: String
	var neg_x_last_val: Dictionary
	var pos_y_equiv: String
	var pos_y_last_val: Dictionary
	var neg_y_equiv: String
	var neg_y_last_val: Dictionary
	func _init(p_name: String, p_pos_x_equiv: String, p_neg_x_equiv: String, p_pos_y_equiv: String, p_neg_y_equiv: String) -> void:
		super(p_name)
		self.pos_x_equiv = p_pos_x_equiv
		self.neg_x_equiv = p_neg_x_equiv
		self.pos_y_equiv = p_pos_y_equiv
		self.neg_y_equiv = p_neg_y_equiv
		self.pos_x_last_val = {}
		self.neg_x_last_val = {}
		self.pos_y_last_val = {}
		self.neg_y_last_val = {}


class TriggerAction extends Action:
	var godot_equiv: String
	var last_val: Dictionary
	func _init(p_name: String, p_godot_equiv: String) -> void:
		super(p_name)
		self.godot_equiv = p_godot_equiv
		self.last_val = {}


class MouseLikeAction extends Action:
	func _init(p_name: String) -> void:
		super(p_name)


class DigitalAction extends Action:
	var godot_equiv: String
	var was_pressed_last: Dictionary
	func _init(p_name: String, p_godot_equiv: String) -> void:
		super(p_name)
		self.godot_equiv = p_godot_equiv
		self.was_pressed_last = {}


class ControllerState:
	var active_action_set: ActionSet
	var handle: int
	
	func _init(p_handle: int = 0, p_active_action_set: ActionSet = null):
		self.handle = p_handle
		self.active_action_set = p_active_action_set

static var steam_inputs: Array[ActionSet] = [
	ActionSet.new(ACTION_SET_IN_GAME_CONTROLS,
		[
			AnalogAction.new("move", "move_right", "move_left", "move_forward", "move_back"),
			MouseLikeAction.new("camera"),
			DigitalAction.new("aim", ""),
			DigitalAction.new("fire", ""),
			DigitalAction.new("jump", "jump"),
			DigitalAction.new("pause_menu", "pause_menu"),
		]
	),
	ActionSet.new(ACTION_SET_MENU_CONTROLS,
		[
			DigitalAction.new("menu_up", "ui_up"),
			DigitalAction.new("menu_down", "ui_down"),
			DigitalAction.new("menu_left", "ui_left"),
			DigitalAction.new("menu_right", "ui_right"),
			DigitalAction.new("menu_select", "ui_accept"),
			DigitalAction.new("menu_cancel", "ui_cancel"),
			DigitalAction.new("close_menu", "ui_cancel"),
		]
	)
]

static func get_action_set(action_set: String) -> ActionSet:
	var res := steam_inputs.filter(func(x: ActionSet): return x.name == action_set)
	if res.size() == 0:
		return null
	return res[0]
