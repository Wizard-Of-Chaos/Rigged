extends Node

class Action:
	var handle: int
	func _init() -> void:
		self.handle = -1
class AnalogAction extends Action:
	var pos_x_equiv: String
	var pos_x_was_pressed_last: bool
	var neg_x_equiv: String
	var neg_x_was_pressed_last: bool
	var pos_y_equiv: String
	var pos_y_was_pressed_last: bool
	var neg_y_equiv: String
	var neg_y_was_pressed_last: bool
	func _init(p_pos_x_equiv: String, p_neg_x_equiv: String, p_pos_y_equiv: String, p_neg_y_equiv: String) -> void:
		super()
		self.pos_x_equiv = p_pos_x_equiv
		self.neg_x_equiv = p_neg_x_equiv
		self.pos_y_equiv = p_pos_y_equiv
		self.neg_y_equiv = p_neg_y_equiv

class DigitalAction extends Action:
	var godot_equiv: String
	var was_pressed_last: bool
	func _init(p_godot_equiv: String) -> void:
		super()
		self.godot_equiv = p_godot_equiv
		self.was_pressed_last = false


var steamInputMapping: Dictionary = {
	# InGameControls
	"move": AnalogAction.new("move_right", "move_left", "move_up", "move_down"),
	"camera": AnalogAction.new("", "", "", ""),
	"aim": DigitalAction.new(""),
	"fire": DigitalAction.new(""),
	"jump": DigitalAction.new("jump"),
	"pause_menu": DigitalAction.new(""),
	# MenuControls
	"menu_up": DigitalAction.new(""),
	"menu_down": DigitalAction.new(""),
	"menu_left": DigitalAction.new(""),
	"menu_right": DigitalAction.new(""),
	"menu_select": DigitalAction.new(""),
	"menu_cancel": DigitalAction.new(""),
	"close_menu": DigitalAction.new(""),
}

var controllers: Array = []

func _ready() -> void:
	Steam.runFrame()
	for actionName in steamInputMapping:
		var action: Action = steamInputMapping[actionName]
		if action is AnalogAction:
			action.handle = Steam.getAnalogActionHandle(actionName)
		else:
			action.handle = Steam.getDigitalActionHandle(actionName)
	controllers = Steam.getConnectedControllers()

func _process(_delta: float) -> void:
	for actionName in steamInputMapping:
		var action: Action = steamInputMapping[actionName]
		for controller in controllers:
			if action is AnalogAction:
				var res := Steam.getAnalogActionData(controller, action.handle)
				translate_analog_input(res, action)
			else:
				var res := Steam.getDigitalActionData(controller, action.handle)
				translate_digital_input(res, action)

func translate_digital_input(p_steam_input: Dictionary, action: DigitalAction) -> void:
	if not p_steam_input.state and not action.was_pressed_last:
		return
	action.was_pressed_last = p_steam_input.state
	var ev := InputEventAction.new()
	ev.pressed = p_steam_input.state
	ev.action = action.godot_equiv
	Input.parse_input_event(ev)
	
func translate_analog_input(p_steam_input: Dictionary, p_action: AnalogAction) -> void:
	# TODO: handle mouse like inputs
	if p_steam_input.x > 0 and InputMap.has_action(p_action.pos_x_equiv):
		Input.action_press(p_action.pos_x_equiv, p_steam_input.x)
		p_action.pos_x_was_pressed_last = true
	elif p_action.pos_x_was_pressed_last and InputMap.has_action(p_action.pos_x_equiv):
		Input.action_release(p_action.pos_x_equiv)
		p_action.pos_x_was_pressed_last = false
	if p_steam_input.x < 0 and InputMap.has_action(p_action.neg_x_equiv):
		Input.action_press(p_action.neg_x_equiv, -p_steam_input.x)
		p_action.neg_x_was_pressed_last = true
	elif p_action.neg_x_was_pressed_last and InputMap.has_action(p_action.neg_x_equiv):
		Input.action_release(p_action.neg_x_equiv)
		p_action.neg_x_was_pressed_last = false
	
	if p_steam_input.y > 0 and InputMap.has_action(p_action.pos_y_equiv):
		Input.action_press(p_action.pos_y_equiv, p_steam_input.y)
		p_action.pos_y_was_pressed_last = true
	elif p_action.pos_y_was_pressed_last and InputMap.has_action(p_action.pos_y_equiv):
		Input.action_release(p_action.pos_y_equiv)
		p_action.pos_y_was_pressed_last = false
	if p_steam_input.y < 0 and InputMap.has_action(p_action.neg_y_equiv):
		Input.action_press(p_action.neg_y_equiv, -p_steam_input.y)
		p_action.neg_y_was_pressed_last = true
	elif p_action.neg_y_was_pressed_last and InputMap.has_action(p_action.neg_y_equiv):
		Input.action_release(p_action.neg_y_equiv)
		p_action.neg_y_was_pressed_last = false
