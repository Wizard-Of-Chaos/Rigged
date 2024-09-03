extends Node


var _controllers: Array[RiggedInputUtils.ControllerState] = []
var _got_action_handles: bool = false


func _ready() -> void:
	Steam.inputInit()
	Steam.enableDeviceCallbacks()
	Steam.runFrame()
	_controllers.resize(RiggedInputUtils.MAX_CONNECTED_CONTROLLERS)
	for i in _controllers.size():
		_controllers[i] = RiggedInputUtils.ControllerState.new()
	for controller: int in Steam.getConnectedControllers():
		var free_slot := _get_controller_slot_for_handle(0)
		_controllers[free_slot].handle = controller
	if _controllers.any(func(c: RiggedInputUtils.ControllerState): return c.handle != 0):
		_get_action_handles()
	Steam.input_device_connected.connect(_on_input_device_connected)
	Steam.input_device_disconnected.connect(_on_input_device_disconnected)
	Steam.input_gamepad_slot_change.connect(_on_input_gamepad_slot_change)


func _get_controller_slot_for_handle(p_handle: int) -> int:
	for i in _controllers.size():
		if _controllers[i].handle == p_handle:
			return i
	return -1


func _process(_delta: float) -> void:
	for controller in _controllers:
		if controller.handle == 0 or controller.active_action_set == null:
			continue
		for action in controller.active_action_set.actions:
			if action is RiggedInputUtils.AnalogAction:
				var res := Steam.getAnalogActionData(controller.handle, action.handle)
				translate_analog_input(res, action, controller.handle)
			elif action is RiggedInputUtils.TriggerAction:
				var res := Steam.getAnalogActionData(controller.handle, action.handle)
				translate_trigger_input(res, action, controller.handle)
			elif action is RiggedInputUtils.MouseLikeAction:
				var res := Steam.getAnalogActionData(controller.handle, action.handle)
				translate_mouse_like_input(res, action, controller.handle)
			elif action is RiggedInputUtils.DigitalAction:
				var res := Steam.getDigitalActionData(controller.handle, action.handle)
				translate_digital_input(res, action, controller.handle)
			else:
				printerr("Unknown action: %s" % action)


func _get_action_handles() -> void:
	var null_handle := false
	for action_set in RiggedInputUtils.steam_inputs:
		action_set.handle = Steam.getActionSetHandle(action_set.name)
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


func translate_mouse_like_input(p_steam_input: Dictionary, _action: RiggedInputUtils.MouseLikeAction, p_device_handle: int) -> void:
	if p_steam_input.x == 0 and p_steam_input.y == 0:
		return
	var ev := InputEventMouseMotion.new()
	# TODO: properly caculate relative
	ev.screen_relative = Vector2(p_steam_input.x, p_steam_input.y)
	ev.relative = Vector2(p_steam_input.x, p_steam_input.y)
	ev.device = get_virtual_device_id(p_device_handle)
	Input.parse_input_event(ev)


func _on_input_device_connected(p_input_handle: int) -> void:
	# INFO: handles are only available once at least one controller has connected
	if not _got_action_handles:
		_get_action_handles()
	var free_slot := _get_controller_slot_for_handle(0)
	# there should only ever be 16 controllers connected in Steam, so should be good to go
	_controllers[free_slot].handle = p_input_handle
	var action_set := RiggedInputUtils.get_action_set(RiggedInputUtils.ACTION_SET_IN_GAME_CONTROLS)
	if action_set != null and action_set.handle != 0:
		Steam.activateActionSet(p_input_handle, action_set.handle)
		_controllers[free_slot].active_action_set = action_set

func _on_input_device_disconnected(p_input_handle: int) -> void:
	var controller_slot := _get_controller_slot_for_handle(p_input_handle)
	_controllers[controller_slot].handle = 0
	_controllers[controller_slot].active_action_set = null
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


func show_binding_panel(p_virtual_device: int) -> void:
	var controller: int = get_controller_handle(p_virtual_device)
	Steam.showBindingPanel(controller)

func get_virtual_device_id(p_input_handle: int) -> int:
	return _get_controller_slot_for_handle(p_input_handle) + RiggedInputUtils.VIRTUAL_DEVICE_OFFSET

func get_controller_handle(p_virtual_device: int) -> int:
	return _controllers[p_virtual_device - RiggedInputUtils.VIRTUAL_DEVICE_OFFSET].handle

func set_active_action_set(p_virtual_device: int, p_action_set: String) -> void:
	var handle := get_controller_handle(p_virtual_device)
	var controller_info := _controllers[_get_controller_slot_for_handle(handle)]
	var action_set := RiggedInputUtils.get_action_set(p_action_set)
	Steam.activateActionSet(handle, action_set.handle)
	controller_info.active_action_set = action_set
