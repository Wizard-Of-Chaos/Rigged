extends Node

class Action:
	var handle: int
	func _init() -> void:
		self.handle = -1
class AnalogAction extends Action:
	var pos_x_equiv: String
	var pos_x_last_val: float
	var neg_x_equiv: String
	var neg_x_last_val: float
	var pos_y_equiv: String
	var pos_y_last_val: float
	var neg_y_equiv: String
	var neg_y_last_val: float
	func _init(p_pos_x_equiv: String, p_neg_x_equiv: String, p_pos_y_equiv: String, p_neg_y_equiv: String) -> void:
		super()
		self.pos_x_equiv = p_pos_x_equiv
		self.neg_x_equiv = p_neg_x_equiv
		self.pos_y_equiv = p_pos_y_equiv
		self.neg_y_equiv = p_neg_y_equiv
		self.pos_x_last_val = 0.0
		self.neg_x_last_val = 0.0
		self.pos_y_last_val = 0.0
		self.neg_y_last_val = 0.0
		

class TriggerAction extends Action:
	var godot_equiv: String
	var last_val: float
	func _init(p_godot_equiv: String) -> void:
		super()
		self.godot_equiv = p_godot_equiv

class MouseLikeAction extends Action:
	func _init() -> void:
		super()

class DigitalAction extends Action:
	var godot_equiv: String
	var was_pressed_last: bool
	func _init(p_godot_equiv: String) -> void:
		super()
		self.godot_equiv = p_godot_equiv
		self.was_pressed_last = false

class ActionSet:
	var actions
	var handle: int

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
var got_action_handles: bool = false

func _ready() -> void:
	Steam.runFrame()

	controllers = Steam.getConnectedControllers()
	if controllers.size() > 0:
		_get_action_handles()
	Steam.input_device_connected.connect(_on_input_device_connected)
	Steam.input_device_disconnected.connect(_on_input_device_disconnected)
	Steam.input_gamepad_slot_change.connect(_on_input_gamepad_slot_change)

func _process(_delta: float) -> void:
	for actionName in steamInputMapping:
		var action: Action = steamInputMapping[actionName]
		for controller in controllers:
			if action is AnalogAction:
				var res := Steam.getAnalogActionData(controller, action.handle)
				translate_analog_input(res, action)
			elif action is TriggerAction:
				var res := Steam.getAnalogActionData(controller, action.handle)
				translate_trigger_input(res, action)
			elif action is MouseLikeAction:
				var res := Steam.getAnalogActionData(controller, action.handle)
				translate_mouse_like_input(res, action)
			else:
				var res := Steam.getDigitalActionData(controller, action.handle)
				translate_digital_input(res, action)

func _get_action_handles() -> void:
	for action_name in steamInputMapping:
		var action: Action = steamInputMapping[action_name]
		if action is AnalogAction or action is TriggerAction or action is MouseLikeAction:
			action.handle = Steam.getAnalogActionHandle(action_name)
		else:
			action.handle = Steam.getDigitalActionHandle(action_name)
	got_action_handles = true


func translate_digital_input(p_steam_input: Dictionary, action: DigitalAction) -> void:
	# Only care about posedges or negedges, there's no logical xnor operator lmao
	if p_steam_input.state and action.was_pressed_last or not p_steam_input.state and not action.was_pressed_last:
		return
	action.was_pressed_last = p_steam_input.state
	
	if p_steam_input.state:
		Input.action_press(action.godot_equiv)
	else:
		Input.action_release(action.godot_equiv)
	
	var ev := InputEventAction.new()
	ev.pressed = p_steam_input.state
	ev.action = action.godot_equivc
	Input.parse_input_event(ev)
	
func translate_analog_input(p_steam_input: Dictionary, p_action: AnalogAction) -> void:
	if clampf(p_steam_input.x, 0.0, 1.0) != p_action.pos_x_last_val and InputMap.has_action(p_action.pos_x_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.pos_x_equiv
		if p_steam_input.x > 0.0:
			Input.action_press(p_action.pos_x_equiv, p_steam_input.x)
			ev.pressed = true
			ev.strength = p_steam_input.x
		else:
			Input.action_release(p_action.pos_x_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.pos_x_last_val = clampf(p_steam_input.x, 0.0, 1.0)
	if clampf(p_steam_input.x, -1.0, 0.0) != p_action.neg_x_last_val and InputMap.has_action(p_action.neg_x_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.neg_x_equiv
		if p_steam_input.x < 0:
			Input.action_press(p_action.neg_x_equiv, -p_steam_input.x)
			ev.pressed = true
			ev.strength = -p_steam_input.x
		else:
			Input.action_release(p_action.neg_x_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.neg_x_last_val = clampf(p_steam_input.x, -1.0, 0.0)
	if clampf(p_steam_input.y, 0.0, 1.0) != p_action.pos_y_last_val and InputMap.has_action(p_action.pos_y_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.pos_y_equiv
		if p_steam_input.y > 0.0:
			Input.action_press(p_action.pos_y_equiv, p_steam_input.y)
			ev.pressed = true
			ev.strength = p_steam_input.y
		else:
			Input.action_release(p_action.pos_y_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.pos_y_last_val = clampf(p_steam_input.y, 0.0, 1.0)
	
	if clampf(p_steam_input.y, -1.0, 0.0) != p_action.neg_y_last_val and InputMap.has_action(p_action.pos_y_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.neg_y_equiv
		if p_steam_input.y < 0.0:
			Input.action_press(p_action.neg_y_equiv, -p_steam_input.y)
			ev.pressed = true
			ev.strength = -p_steam_input.y
		else:
			Input.action_release(p_action.neg_y_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.neg_y_last_val = clampf(p_steam_input.y, -1.0, 0.0)

func translate_trigger_input(p_steam_input: Dictionary, p_action: TriggerAction) -> void:
	if p_steam_input.x != p_action.last_val and InputMap.has_action(p_action.godot_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.godot_equiv
		if p_steam_input.x > 0.0:
			Input.action_press(p_action.godot_equiv)
			ev.pressed = true
			ev.strength = p_steam_input.x
		else:
			Input.action_release(p_action.godot_equiv)
			ev.pressed = false
			ev.strength = p_steam_input.x
		Input.parse_input_event(ev)

func translate_mouse_like_input(p_steam_input: Dictionary, action: MouseLikeAction) -> void:
	pass

func _on_input_device_connected(p_input_handle: int):
	# INFO: handles are only available once at least one controller has connected
	if not got_action_handles:
		_get_action_handles()


func _on_input_device_disconnected(p_input_handle: int):
	pass

func _on_input_gamepad_slot_change(p_app_id: int, p_device_handle: int, p_deivce_type: int, p_old_gamepad_slot: int, p_new_gamepad_slot: int):
	pass
