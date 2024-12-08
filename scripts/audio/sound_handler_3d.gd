extends FmodEventEmitter3D
#Use for anything positional
@onready var event_id: String = self.get_event_name()
@onready var event_gu: String = self.get_event_guid()

func make_one_shot(p_event_name: String, params: Dictionary = {}, p_attached: bool = true):
	self.auto_release = true #this deletes the node after it plays once
	self.attached = p_attached
	self.event_name = p_event_name
	#self.set_preload_event(true)
	for n in params:
		self.set_parameter(n, params[n])
	
func make_loop(p_event_name: String, params: Dictionary = {}, p_attached: bool = true):
	self.p_event_name = event_name
	self.attached = p_attached	#self.set_preload_event(true)
	for n in params:
		self.set_parameter(n, params[n])
	
