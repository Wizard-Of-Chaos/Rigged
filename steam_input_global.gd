extends Node


var _controllers: Array[int] = []
var _got_action_handles: bool = false


func _ready() -> void:
	Steam.inputInit()
	Steam.enableDeviceCallbacks()
	Steam.runFrame()
	_controllers.resize(RiggedInputUtils.MAX_CONNECTED_CONTROLLERS)
	for controller in Steam.getConnectedControllers():
		var free_slot := _controllers.find(0)
		_controllers[free_slot] = controller
	if _controllers.any(func(x): return x != 0):
		_get_action_handles()
	Steam.input_device_connected.connect(_on_input_device_connected)
	Steam.input_device_disconnected.connect(_on_input_device_disconnected)
	Steam.input_gamepad_slot_change.connect(_on_input_gamepad_slot_change)


func _process(_delta: float) -> void:
	for action_set in RiggedInputUtils.steam_inputs:
		for action in action_set.actions:
			for controller in _controllers:
				if controller == 0:
					continue
				if action is RiggedInputUtils.AnalogAction:
					var res := Steam.getAnalogActionData(controller, action.handle)
					translate_analog_input(res, action, controller)
				elif action is RiggedInputUtils.TriggerAction:
					var res := Steam.getAnalogActionData(controller, action.handle)
					translate_trigger_input(res, action, controller)
				elif action is RiggedInputUtils.MouseLikeAction:
					var res := Steam.getAnalogActionData(controller, action.handle)
					translate_mouse_like_input(res, action, controller)
				else:
					var res := Steam.getDigitalActionData(controller, action.handle)
					translate_digital_input(res, action, controller)


func _get_action_handles() -> void:
	var null_handle := false
	for action_set in RiggedInputUtils.steam_inputs:
		for action in action_set.actions:
			if action is RiggedInputUtils.AnalogAction or action is RiggedInputUtils.TriggerAction or action is RiggedInputUtils.MouseLikeAction:
				action.handle = Steam.getAnalogActionHandle(action.name)
			else:
				action.handle = Steam.getDigitalActionHandle(action.name)
			if action.handle == 0:
				null_handle = true
				print("Got a null action handle for action %s" % action.name)
	_got_action_handles = not null_handle



func translate_digital_input(p_steam_input: Dictionary, p_action: RiggedInputUtils.DigitalAction, p_device_handle: int) -> void:
	# Only care about posedges or negedges, there's no logical xnor operator lmao
	if p_steam_input.state and p_action.was_pressed_last.get_or_add(p_device_handle, false) or not p_steam_input.state and not p_action.was_pressed_last.get_or_add(p_device_handle, false):
		return
	p_action.was_pressed_last[p_device_handle] = p_steam_input.state
	
	if p_steam_input.state:
		Input.action_press(p_action.godot_equiv)
	else:
		Input.action_release(p_action.godot_equiv)
	
	var ev := InputEventAction.new()
	ev.pressed = p_steam_input.state
	ev.action = p_action.godot_equiv
	ev.device = get_virtual_device_id(p_device_handle)
	Input.parse_input_event(ev)


func translate_analog_input(p_steam_input: Dictionary, p_action: RiggedInputUtils.AnalogAction, p_device_handle: int) -> void:
	if clampf(p_steam_input.x, 0.0, 1.0) != p_action.pos_x_last_val.get_or_add(p_device_handle, 0.0) and InputMap.has_action(p_action.pos_x_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.pos_x_equiv
		ev.device = get_virtual_device_id(p_device_handle)
		if p_steam_input.x > 0.0:
			Input.action_press(p_action.pos_x_equiv, p_steam_input.x)
			ev.pressed = true
			ev.strength = p_steam_input.x
		else:
			Input.action_release(p_action.pos_x_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.pos_x_last_val[p_device_handle] = clampf(p_steam_input.x, 0.0, 1.0)

	if clampf(p_steam_input.x, -1.0, 0.0) != p_action.neg_x_last_val.get_or_add(p_device_handle, 0.0) and InputMap.has_action(p_action.neg_x_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.neg_x_equiv
		ev.device = get_virtual_device_id(p_device_handle)
		if p_steam_input.x < 0.0:
			Input.action_press(p_action.neg_x_equiv, -p_steam_input.x)
			ev.pressed = true
			ev.strength = -p_steam_input.x
		else:
			Input.action_release(p_action.neg_x_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.neg_x_last_val[p_device_handle] = clampf(p_steam_input.x, -1.0, 0.0)

	if clampf(p_steam_input.y, 0.0, 1.0) != p_action.pos_y_last_val.get_or_add(p_device_handle, 0.0) and InputMap.has_action(p_action.pos_y_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.pos_y_equiv
		ev.device = get_virtual_device_id(p_device_handle)
		if p_steam_input.y > 0.0:
			Input.action_press(p_action.pos_y_equiv, p_steam_input.y)
			ev.pressed = true
			ev.strength = p_steam_input.y
		else:
			Input.action_release(p_action.pos_y_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.pos_y_last_val[p_device_handle] = clampf(p_steam_input.y, 0.0, 1.0)
	
	if clampf(p_steam_input.y, -1.0, 0.0) != p_action.neg_y_last_val.get_or_add(p_device_handle, 0.0) and InputMap.has_action(p_action.neg_y_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.neg_y_equiv
		ev.device = get_virtual_device_id(p_device_handle)
		if p_steam_input.y < 0.0:
			Input.action_press(p_action.neg_y_equiv, -p_steam_input.y)
			ev.pressed = true
			ev.strength = -p_steam_input.y
		else:
			Input.action_release(p_action.neg_y_equiv)
			ev.pressed = false
			ev.strength = 0.0
		Input.parse_input_event(ev)
		p_action.neg_y_last_val[p_device_handle] = clampf(p_steam_input.y, -1.0, 0.0)


func translate_trigger_input(p_steam_input: Dictionary, p_action: RiggedInputUtils.TriggerAction, p_device_handle: int) -> void:
	if p_steam_input.x != p_action.last_val.get_or_add(p_device_handle, 0.0) and InputMap.has_action(p_action.godot_equiv):
		var ev := InputEventAction.new()
		ev.action = p_action.godot_equiv
		ev.device = get_virtual_device_id(p_device_handle)
		if p_steam_input.x > 0.0:
			Input.action_press(p_action.godot_equiv)
			ev.pressed = true
			ev.strength = p_steam_input.x
		else:
			Input.action_release(p_action.godot_equiv)
			ev.pressed = false
			ev.strength = p_steam_input.x
		Input.parse_input_event(ev)
		p_action.last_val[p_device_handle] = p_steam_input.x


func translate_mouse_like_input(p_steam_input: Dictionary, action: RiggedInputUtils.MouseLikeAction, p_device_handle: int) -> void:
	if p_steam_input.x == 0 and p_steam_input.y == 0:
		return
	var ev := InputEventMouseMotion.new()
	# TODO: properly caculate relative
	ev.screen_relative = Vector2(p_steam_input.x, p_steam_input.y)
	ev.relative = Vector2(p_steam_input.x, p_steam_input.y)
	ev.device = get_virtual_device_id(p_device_handle)
	Input.parse_input_event(ev)


func _on_input_device_connected(p_input_handle: int):
	# INFO: handles are only available once at least one controller has connected
	if not _got_action_handles:
		_get_action_handles()
	var free_slot := _controllers.find(0)
	# there should only ever be 16 controllers connected in Steam, so should be good to go
	_controllers[free_slot] = p_input_handle
	Steam.activateActionSet(p_input_handle, 0)

func _on_input_device_disconnected(p_input_handle: int):
	var controller_slot := _controllers.find(p_input_handle)
	_controllers[controller_slot] = 0
	for action_set in RiggedInputUtils.steam_inputs:
		for action in action_set.actions:
			if action is RiggedInputUtils.AnalogAction:
				action.pos_x_last_val.erase(p_input_handle)
				action.neg_x_last_val.erase(p_input_handle)
				action.pos_y_last_val.erase(p_input_handle)
				action.neg_y_last_val.erase(p_input_handle)
			elif action is RiggedInputUtils.TriggerAction:
				action.last_val.erase(p_input_handle)
			elif action is RiggedInputUtils.DigitalAction:
				action.was_pressed_last.erase(p_input_handle)

func _on_input_gamepad_slot_change(p_app_id: int, p_device_handle: int, p_device_type: int, p_old_gamepad_slot: int, p_new_gamepad_slot: int):
	print("slot change:\n\tapp_id: %s \n\tdevice_handle: %s\n\tdevice_type: %s \n\told_slot: %s\n\tnew_slot: %s \n\t" % [p_app_id, p_device_handle, p_device_type, p_old_gamepad_slot, p_new_gamepad_slot])



func show_binding_panel(p_virtual_device: int):
	var controller: int = _controllers[p_virtual_device - RiggedInputUtils.VIRTUAL_DEVICE_OFFSET]
	Steam.showBindingPanel(controller)

func get_virtual_device_id(p_input_handle: int):
	return _controllers.find(p_input_handle) + RiggedInputUtils.VIRTUAL_DEVICE_OFFSET
